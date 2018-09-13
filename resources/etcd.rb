# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
resource_name :etcd

property :cluster_ips, Array
property :etcd_key_name, String
property :etcd_key_ttl, String
property :etcd_key_value, String
property :etcd_host, String, default: '127.0.0.1'
property :etcd_port, Integer, default: 2379
property :hostname, String
property :installation_method, String
property :local_etcd_ips, Array
property :repository, String
property :target_platform, String
property :source_version, String
property :vendor_version, String

action_class do
  include InstallationHelper
  include EtcdHelper
  # etcd functionality taken from https://github.com/chef-cookbooks/etcd/blob/master/libraries/etcd_key.rb

  def etcd_client
    require 'etcd'
    ::Etcd.client(host: new_resource.etcd_host, port: new_resource.etcd_port)
  end

  def key_exist?
    true if etcd_client.get(key)
  rescue Etcd::KeyNotFound, Errno::ECONNREFUSED
    false
  end

  def with_retries(&_block)
    tries = 5
    begin
      yield
      # Only catch errors that can be fixed with retries.
    rescue Errno::ECONNREFUSED
      sleep 5
      tries -= 1
      retry if tries > 0
      raise
    end
  end
end

action :install do
  run_installation('etcd', new_resource.target_platform, new_resource.installation_method)

  chef_gem 'etcd' do
    action :install
    compile_time false
  end
end

action :install_from_vendor do
  package 'etcd' do
    action :install
    version lazy { new_resource.vendor_version if version_available?('etcd', new_resource.vendor_version, new_resource.target_platform) }
  end
end

action :install_from_source do
  user 'etcd' do
    comment 'User for etcd'
    home '/var/lib/etcd'
    shell '/bin/false'
  end

  group 'etcd' do
    action :create
    members 'etcd'
    append true
  end

  directory '/etc/etcd' do
    owner 'etcd'
    group 'etcd'
    mode '0755'
    action :create
    notifies :create, 'directory[/var/lib/etcd]', :immediately
  end

  directory '/var/lib/etcd' do
    owner 'etcd'
    group 'etcd'
    mode '0755'
    action :nothing
  end

  remote_file 'download_etcd' do
    path "#{Chef::Config[:file_cache_path]}/etcd-#{new_resource.source_version}-linux-amd64.tgz"
    action :create
    source new_resource.repository
    mode '0755'
    notifies :run, 'execute[untar_etcd]', :immediately
  end

  execute 'untar_etcd' do
    command "tar -xzvf #{Chef::Config[:file_cache_path]}/etcd-#{new_resource.source_version}-linux-amd64.tgz -C #{Chef::Config[:file_cache_path]}/"
    action :nothing
    notifies :run, 'execute[move_etcd]', :immediately
  end

  execute 'move_etcd' do
    command "mv #{Chef::Config[:file_cache_path]}/etcd-#{new_resource.source_version}-linux-amd64/etcd /usr/bin/etcd && chown etcd:etcd /usr/bin/etcd"
    action :nothing
    notifies :run, 'execute[move_etcdctl]', :immediately
  end

  execute 'move_etcdctl' do
    command "mv #{Chef::Config[:file_cache_path]}/etcd-#{new_resource.source_version}-linux-amd64/etcdctl /usr/bin/etcdctl && chown etcd:etcd /usr/bin/etcdctl"
    action :nothing
  end
end

action :configure do
  advertise_client_urls = get_etcd_server_urls(new_resource.local_etcd_ips)
  advertise_peer_urls = advertise_client_urls.gsub(/:2379/, ':2380')

  etcd_name = get_etcd_name(new_resource.cluster_ips)
  cluster_urls = get_etcd_cluster_urls(new_resource.cluster_ips)

  template '/etc/etcd/etcd.conf' do
    source 'etcd.conf.erb'
    variables(
      ETCD_NAME: etcd_name,
      ETCD_DATA_DIR: '/var/lib/etcd/default.etcd',
      ETCD_LISTEN_CLIENT_URLS: 'http://0.0.0.0:2379',
      ETCD_INITIAL_ADVERTISE_PEER_URLS: advertise_peer_urls,
      ETCD_ADVERTISE_CLIENT_URLS: advertise_client_urls,
      ETCD_INITIAL_CLUSTER: cluster_urls,
      ETCD_INITIAL_CLUSTER_STATE: 'new'
    )
    action :create
    notifies :create, 'systemd_unit[etcd.service]', :immediately
  end

  systemd_unit 'etcd.service' do
    content(
      Unit: {
        Description: 'Etcd',
        Documentation: 'https://coreos.com/etcd',
        After: 'network.target',
      },
      Service: {
        EnvironmentFile: '/etc/etcd/etcd.conf',
        Type: 'notify',
        ExecStart: '/usr/bin/etcd',
        Restart: 'always',
        User: 'etcd',
        Group: 'etcd',
      },
      Install: {
        WantedBy: 'multi-user.target',
      }
    )
    action :nothing
    notifies :enable, 'service[etcd]', :immediately
    notifies :start, 'service[etcd]', :immediately
  end

  service 'etcd' do
    action :nothing
  end
end

action :set_key do
  opts = { value: new_resource.etcd_key_value }
  opts[:ttl] = new_resource.etcd_key_ttl if new_resource.etcd_key_ttl
  with_retries { etcd_client.set(new_resource.etcd_key_name, opts) }
end

action :delete_key do
  with_retries { etcd_client.delete(etcd_key_name) } if key_exist?
end
