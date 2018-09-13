# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
resource_name :flannel

property :etcd_cluster_ips, Array
property :etcd_prefix, String
property :flannel_interface, String
property :flannel_subnet, String
property :installation_method, String
property :repository, String
property :role, String
property :target_platform, String
property :source_version, String
property :vendor_version, String

action_class do
  include EtcdHelper
  include InstallationHelper
  include KubernetesHelper
  include TestKitchenHelper
end

action :install do
  run_installation('flannel', new_resource.target_platform, new_resource.installation_method)

  directory '/etc/cni/net.d/' do
    action :create
    recursive true
    mode '0755'
  end
end

action :install_from_vendor do
  package 'flannel' do
    action :install
    version lazy { new_resource.vendor_version if version_available?('flannel', vendor_version, target_platform) }
  end
end

action :install_from_source do
  directory '/etc/kubernetes/' do
    owner 'root'
    mode '0755'
    action :create
    notifies :create, 'remote_file[download_flanneld]', :immediately
  end

  remote_file 'download_flanneld' do
    path "#{Chef::Config[:file_cache_path]}/flannel-#{new_resource.source_version}-linux-amd64.tar.gz"
    action :create
    source new_resource.repository
    mode '0755'
    notifies :run, 'execute[untar_flannel]', :immediately
  end

  execute 'untar_flannel' do
    command "tar -xzvf #{Chef::Config[:file_cache_path]}/flannel-#{new_resource.source_version}-linux-amd64.tar.gz -C #{Chef::Config[:file_cache_path]}/"
    action :nothing
    notifies :run, 'execute[move_flanneld]', :immediately
  end

  execute 'move_flanneld' do
    command "mv #{Chef::Config[:file_cache_path]}/flanneld /usr/bin/flanneld"
    action :nothing
  end
end

action :configure do
  final_installation_method = node[cookbook_name]['flannel']['final_installation_method']
  # Write flannel config to etcd
  etcd 'set_key' do
    action :set_key
    etcd_key_name "#{new_resource.etcd_prefix}/config"
    # Note: Flannel expects a hash, if a hash is passed here ruby's .to_s would break
    # Flannel's expectation
    etcd_key_value "{
      \"Network\": \"#{new_resource.flannel_subnet}\",
       \"SubnetLen\": 24,
       \"Backend\": {
          \"Type\": \"vxlan\"
       }
    }"
    only_if { new_resource.role == 'master' || (test_kitchen_active? && role == 'minion') }
  end

  cookbook_file '/etc/cni/net.d/10-flannel.conf' do
    source 'cni/10-flannel.conf'
    owner 'root'
    mode '0644'
    action :create
    only_if { final_installation_method == 'source' }
  end

  # Configure Flannel to get settings from etcd on master
  if %w(redhat centos).include?(new_resource.target_platform) && final_installation_method == 'vendor'
    template_path = '/etc/sysconfig/flanneld'
    systemd = false
  else
    template_path = '/etc/kubernetes/flanneld'
    systemd = true
  end

  flanneld_options = {
    FLANNEL_ETCD_ENDPOINTS: get_etcd_server_urls(new_resource.etcd_cluster_ips),
    FLANNEL_ETCD_PREFIX: new_resource.etcd_prefix,
    SYSTEMD: systemd,
  }

  # NOTE: You only want to do this in a Vagrant environment!
  flanneld_options[:FLANNEL_INTERFACE] = new_resource.flannel_interface unless new_resource.flannel_interface.nil?

  template template_path do
    variables flanneld_options
    action :create
    if final_installation_method == 'vendor'
      notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
      notifies :register_restart, 'kubernetes_chef_cookbook_service[flanneld]', :immediately
      notifies :register_restart, 'kubernetes_chef_cookbook_service[docker]', :immediately
      notifies :start, 'service[flanneld]', :immediately
      notifies :enable, 'service[flanneld]', :immediately
    end
  end

  if final_installation_method == 'source'
    cookbook_file '/etc/systemd/system/flanneld.service' do
      source 'systemd/flanneld.service'
      owner 'root'
      mode '0644'
      action :create
      notifies :start, 'service[flanneld]', :immediately
      notifies :enable, 'service[flanneld]', :immediately
      notifies :run, 'bash[set_flannel_options_in_docker]', :delayed
    end

    # Using bash here instead of template, to prevent a getter being executed before the file exists
    bash 'set_flannel_options_in_docker' do
      code <<-EOH
        source /run/flannel/subnet.env
        ifconfig docker0 ${FLANNEL_SUBNET}
        rm /etc/docker/daemon.json
cat >> /etc/docker/daemon.json <<EOF
{
  "bip": "${FLANNEL_SUBNET}",
  "iptables": false,
  "mtu": ${FLANNEL_MTU}
}
EOF
        systemctl daemon-reload
      EOH
      action :nothing
      notifies :stop, 'service[docker]', :before
      notifies :start, 'service[docker]', :immediately
    end
  end

  service 'flanneld' do
    action :nothing
  end

  service 'docker' do
    action :nothing
  end

  ['systemctl daemon-reload', 'flanneld', 'docker'].each do |svc|
    kubernetes_chef_cookbook_service svc do
      action :nothing
    end
  end
end
