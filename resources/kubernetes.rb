# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
require 'mixlib/shellout'
Chef::Resource::Template.send(:include, EtcdHelper)

resource_name :kubernetes

property :additional_packages, Array
property :cgroup_driver, String
property :etcd_cluster_ips, Array
property :installation_method, String
property :instance_ip, String
property :cluster_name, String
property :kube_ip_range, String
property :kubernetes_version, String
property :kube_service_ip, String
property :role, String
property :repository, String
property :root_ca_installation_method, String
property :root_ca_repository, String
property :root_ca_key_repository, String
property :services, Array
property :target_platform, String, required: true
property :virtual_api_server_ip, String

action_class do
  include EtcdHelper
  include InstallationHelper
  include KubernetesHelper
end

action :install do
  run_installation('kubernetes', new_resource.target_platform, new_resource.installation_method)

  user 'kube' do
    action :create
  end

  group 'kube' do
    members ['kube']
    action :create
  end

  directory '/etc/kubernetes/' do
    owner 'root'
    mode '0755'
    action :create
  end
end

action :install_from_vendor do
  case target_platform
  when 'centos', 'redhat' # ~FC024 Foodcritic recognizes here that we are doing a OS recognition, but expects exotic OS to be added as well
    # RedHat and CentOS have kubernetes as well as kubernetes-master and -node packages
    # available. For clear distinction let's only install the needed packages
    kubernetes_package = "kubernetes-#{yum_role(role)}"
  else
    kubernetes_package = 'kubernetes'
  end
  package kubernetes_package

  # Get Kubernetes version and warn if they mismatch to the desired version
  vendor_kubernetes_version = installed_kubernetes_version
  if Gem::Version.new(vendor_kubernetes_version) < Gem::Version.new(kubernetes_version)
    Chef::Log.warn("#{target_platform} only has vendor packages for Kubernetes #{vendor_kubernetes_version}. Adjusting installation.")
  end
end

action :install_from_source do
  new_resource.additional_packages.each do |pkg|
    remote_file "download_#{pkg}" do
      path "/usr/bin/#{pkg}"
      source "#{new_resource.repository}/#{pkg}"
      mode '0755'
    end
  end
end

action :init_services do
  # services are taken from https://github.com/kubernetes/contrib/tree/master/init/systemd
  new_resource.services.each do |svc|
    cookbook_file "/etc/systemd/system/#{svc}.service" do
      source "systemd/#{svc}.service"
      owner 'root'
      mode '0644'
      action :create
    end
  end
end

action :configure do
  # Init services needed below
  action_init_services

  config_variables = {
    KUBE_LOGTOSTDERR: '"--logtostderr=true"',
    KUBE_ETCD_SERVERS: '"--etcd-servers=' + get_etcd_server_urls(new_resource.etcd_cluster_ips) + '"',
    KUBE_LOG_LEVEL: '"--v=0"',
    KUBE_ALLOW_PRIV: '"--allow-privileged=false"',
    KUBE_MASTER: '"--master=http://' + new_resource.virtual_api_server_ip + ':8080"',
  }

  config_variables[:KUBE_PROXY_ARGS] = '"--hostname-override=' + new_resource.instance_ip + ' --cluster-cidr=' + new_resource.kube_ip_range + '"' if new_resource.role == 'minion'

  # Configure kubernetes
  template '/etc/kubernetes/config' do
    source 'config.erb'
    variables config_variables
    notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[docker]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-proxy]', :immediately if new_resource.role == 'minion'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-apiserver]', :immediately if new_resource.role == 'master'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-controller-manager]', :immediately if new_resource.role == 'master'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-scheduler]', :immediately if new_resource.role == 'master'
  end

  new_resource.services.each do |svc|
    next if svc == 'kubelet'
    service "Enable #{svc}" do
      service_name svc
      action :enable
    end

    # This adds each custom service resource to the collection in the correct
    # order, and register only those that are affeted by changes upon notification
    kubernetes_chef_cookbook_service svc do
      action :nothing
    end
  end

  ['systemctl daemon-reload', 'docker'].each do |svc|
    kubernetes_chef_cookbook_service svc do
      action :nothing
    end
  end

  if Gem::Version.new(installed_kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    directory '/srv/kubernetes' do
      owner 'root'
      group 'root'
      action :create
    end

    directory '/var/run/kubernetes' do
      owner 'root'
      group 'root'
      action :create
    end

    # TODO: Implement getting ca from databag
    remote_file 'download_ca' do
      path '/srv/kubernetes/ca.pem'
      action :create
      source new_resource.root_ca_repository
      mode '0644'
      notifies :create, 'remote_file[download_ca_key]', :immediately
      not_if { ::File.exist?('/srv/kubernetes/ca.pem') && new_resource.root_ca_installation_method != 'url' }
    end

    remote_file 'download_ca_key' do
      path '/srv/kubernetes/ca-key.pem'
      action :nothing
      source new_resource.root_ca_key_repository
      mode '0644'
    end
  end
end

action :configure_minion do
  # Configure kubelet
  directory '/var/lib/kubelet' do
    owner 'kube'
    group 'kube'
  end

  kubelet_variables = {
    KUBELET_HOSTNAME: '"--hostname-override=' + new_resource.instance_ip + '"',
  }

  vendor_kubernetes_version = installed_kubernetes_version
  kubelet_variables[:KUBELET_API_SERVER] = '"--api-servers=http://' + virtual_api_server_ip + ':8080"' if Gem::Version.new(vendor_kubernetes_version) < Gem::Version.new(node[cookbook_name]['config_version_threshold'])
  kubelet_variables[:KUBE_CONFIG] = '"--kubeconfig=/etc/kubernetes/worker.kubeconfig"' if Gem::Version.new(vendor_kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
  kubelet_variables[:KUBELET_CLUSTER_IP] = node[cookbook_name]['kube-dns']['cluster_ip']
  kubelet_variables[:KUBELET_CLUSTER_DOMAIN] = node[cookbook_name]['kube-dns']['cluster_domain']

  # Adjust the cgroup driver for kubelet and docker
  if %w(redhat centos).include?(new_resource.target_platform) && node[cookbook_name]['docker']['final_installation_method'] == 'vendor'
    cgroup_driver = 'systemd'
    ruby_block 'change_docker_cgroup' do
      block do
        file = Chef::Util::FileEdit.new('/usr/lib/systemd/system/docker.service')
        # Make sure docker uses the same cgroup as the kubelet does
        file.search_file_replace_line(/--exec-opt native.cgroupdriver=systemd \\/, "--exec-opt native.cgroupdriver=#{cgroup_driver} \\")
        file.write_file
      end
      notifies :reload, 'service[docker]', :immediately
      notifies :restart, 'service[docker]', :immediately
    end
    kubelet_variables[:KUBELET_CGROUP_DRIVER] = '"--cgroup-driver=' + cgroup_driver + ' --runtime-cgroups=/systemd/system.slice --kubelet-cgroups=/systemd/system.slice"'
    node.normal[cookbook_name]['kubernetes']['cgroup_driver'] = cgroup_driver
  end

  service 'docker' do
    action :nothing
  end

  template '/etc/kubernetes/kubelet' do
    source 'kubelet.erb'
    variables kubelet_variables
    action :create
    notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kubelet]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-proxy]', :immediately
    notifies :enable, 'service[enable_kubelet]', :immediately
  end

  service 'enable_kubelet' do
    service_name 'kubelet'
    action :nothing
  end

  if Gem::Version.new(vendor_kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])

    template '/home/worker_openssl.conf' do # ~FC033 The Foodcritic version on the CI does not find files in sub-directories.
      source 'pki/worker_openssl.conf.erb'
      variables(
        IPADDRESS: new_resource.instance_ip
      )
      action :nothing
    end

    execute 'generate_worker_cert' do
      command <<-EOH
        openssl genrsa -out /srv/kubernetes/worker-key.pem 2048
        openssl req -new -key /srv/kubernetes/worker-key.pem -out worker.csr -subj "/CN=system:node:worker" -config worker_openssl.conf
        openssl x509 -req -in worker.csr -CA /srv/kubernetes/ca.pem -CAkey /srv/kubernetes/ca-key.pem -CAcreateserial -out /srv/kubernetes/worker.pem -days 10000 -extensions v3_req -extfile worker_openssl.conf
        rm worker.csr
      EOH
      cwd '/home'
      action :run
      notifies :create, 'template[/home/worker_openssl.conf]', :before
      notifies :delete, 'template[/home/worker_openssl.conf]', :immediately
      notifies :run, 'execute[generate_kube_proxy_cert]', :immediately
      not_if { ::File.exist?('/srv/kubernetes/worker-key.pem') }
    end

    execute 'generate_kube_proxy_cert' do
      command <<-EOH
        openssl genrsa -out /srv/kubernetes/kube-proxy-key.pem 2048
        openssl req -new -key /srv/kubernetes/kube-proxy-key.pem -out kube-proxy.csr -subj "/CN=system:kube-proxy"
        openssl x509 -req -in kube-proxy.csr -CA /srv/kubernetes/ca.pem -CAkey /srv/kubernetes/ca-key.pem -CAcreateserial -out /srv/kubernetes/kube-proxy.pem -days 10000
        rm kube-proxy.csr
      EOH
      cwd '/home'
      action :nothing
    end

    kubectl 'worker_config' do
      action :create
      certificate_authority '/srv/kubernetes/ca.pem'
      client_certificate '/srv/kubernetes/worker.pem'
      client_key '/srv/kubernetes/worker-key.pem'
      cluster_name new_resource.cluster_name
      context 'default'
      file '/etc/kubernetes/worker.kubeconfig'
      user 'system:node:worker'
      virtual_api_server_ip new_resource.virtual_api_server_ip
    end

    kubectl 'proxy_config' do
      action :create
      certificate_authority '/srv/kubernetes/ca.pem'
      client_certificate '/srv/kubernetes/kube-proxy.pem'
      client_key '/srv/kubernetes/kube-proxy-key.pem'
      cluster_name new_resource.cluster_name
      context 'default'
      file '/etc/kubernetes/kube-proxy.kubeconfig'
      user 'kube-proxy'
      virtual_api_server_ip new_resource.virtual_api_server_ip
    end
  end

  ['docker', 'kubelet', 'systemctl daemon-reload'].each do |svc|
    kubernetes_chef_cookbook_service svc do
      action :nothing
    end
  end
end

action :configure_master do
  vendor_kubernetes_version = installed_kubernetes_version
  if Gem::Version.new(vendor_kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    # Generate the admin key pair
    execute 'generate_admin_cert' do
      command <<-EOH
        openssl genrsa -out /srv/kubernetes/admin-key.pem 2048
        openssl req -new -key /srv/kubernetes/admin-key.pem -out admin.csr -subj "/CN=admin"
        openssl x509 -req -in admin.csr -CA /srv/kubernetes/ca.pem -CAkey /srv/kubernetes/ca-key.pem -CAcreateserial -out /srv/kubernetes/admin.pem -days 10000
        rm admin.csr
      EOH
      cwd '/home'
      action :run
      not_if { ::File.exist?('/srv/kubernetes/admin-key.pem') }
      notifies :run, 'execute[generate_api_server_cert]', :immediately
    end

    # Generate the API server certificate
    template '/home/apiserver_openssl.conf' do # ~FC033 The Foodcritic version on the CI does not find files in sub-directories.
      source 'pki/apiserver_openssl.conf.erb'
      variables(
        VIRTUAL_API_SERVER_IP: new_resource.virtual_api_server_ip,
        KUBE_SERVICE_IP: new_resource.kube_service_ip
      )
      action :nothing
    end

    execute 'generate_api_server_cert' do
      command <<-EOH
        openssl genrsa -out /srv/kubernetes/apiserver-key.pem 2048
        openssl req -new -key /srv/kubernetes/apiserver-key.pem -out apiserver.csr -subj "/CN=kubernetes" -config apiserver_openssl.conf
        openssl x509 -req -in apiserver.csr -CA /srv/kubernetes/ca.pem -CAkey /srv/kubernetes/ca-key.pem -CAcreateserial -out /srv/kubernetes/apiserver.pem -days 10000 -extensions v3_req -extfile apiserver_openssl.conf
        rm apiserver.csr
      EOH
      cwd '/home'
      action :nothing
      notifies :create, 'template[/home/apiserver_openssl.conf]', :before
      notifies :delete, 'template[/home/apiserver_openssl.conf]', :immediately
    end
  else
    # Initilize Kubernetes Cluster with Certificate
    cert_info = "IP:#{virtual_api_server_ip},"
    cert_info += "IP:#{kube_service_ip},"
    cert_info += 'DNS:kubernetes,DNS:kubernetes.default,DNS:kubernetes.default.svc,DNS:kubernetes.default.svc.cluster.local'

    cookbook_file 'cert script' do
      source 'make-ca-cert.sh'
      path '/home/make-ca-cert.sh'
      action :nothing
    end

    execute 'Generate communication key' do
      command "bash make-ca-cert.sh #{virtual_api_server_ip} #{cert_info}"
      cwd '/home'
      action :run
      not_if { ::Dir.exist?('/srv/kubernetes') }
      notifies :create, 'cookbook_file[cert script]', :before
      notifies :delete, 'cookbook_file[cert script]', :immediately
      notifies :run, 'execute[rename_ca_apikey]', :immediately
    end

    execute 'rename_ca_apikey' do
      command <<-EOH
        mv ca.crt ca.pem
      EOH
      cwd '/srv/kubernetes'
      only_if { ::File.exist?('/srv/kubernetes/ca.crt') }
      notifies :run, 'execute[rename_apiserver_cert]', :immediately
    end

    execute 'rename_apiserver_cert' do
      command <<-EOH
        mv server.cert apiserver.pem
      EOH
      cwd '/srv/kubernetes'
      only_if { ::File.exist?('/srv/kubernetes/server.cert') }
      notifies :run, 'execute[rename_apiserver_key]', :immediately
    end

    execute 'rename_apiserver_key' do
      command <<-EOH
        mv server.key apiserver-key.pem
      EOH
      cwd '/srv/kubernetes'
      only_if { ::File.exist?('/srv/kubernetes/server.key') }
    end
  end

  apiserver_flags = {
    KUBE_ETCD_SERVERS: '"--etcd-servers=' + get_etcd_server_urls(new_resource.etcd_cluster_ips) + '"',
    KUBE_SERVICE_ADDRESSES: '"--service-cluster-ip-range=' + new_resource.kube_ip_range + '"',
    KUBE_ADMISSION_CONTROL: '"--admission-control=NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,ServiceAccount,ResourceQuota"',
    KUBE_API_ARGS: '"--client-ca-file=/srv/kubernetes/ca.pem --tls-cert-file=/srv/kubernetes/apiserver.pem --tls-private-key-file=/srv/kubernetes/apiserver-key.pem"',
    KUBE_BIND_ADDRESS: '"--bind-address=' + new_resource.virtual_api_server_ip + '"',
  }

  if Gem::Version.new(vendor_kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    apiserver_flags[:KUBE_API_ADDRESS] = '"--insecure-bind-address=0.0.0.0"'
    apiserver_flags[:KUBE_API_PORT] = '"--insecure-port=8080"'
  else
    apiserver_flags[:KUBE_API_ADDRESS] = '"--address=0.0.0.0"'
    apiserver_flags[:KUBE_API_PORT] = '"--port=8080"'
    apiserver_flags[:KUBELET_PORT] = '"--kubelet-port=10250"'
  end

  # Configure the API server
  template '/etc/kubernetes/apiserver' do
    source 'apiserver.erb'
    variables apiserver_flags
    action :create
    notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-apiserver]', :immediately
  end

  # Setup the controller manager
  template '/etc/kubernetes/controller-manager' do
    source 'controller-manager.erb'
    variables(
      KUBE_CONTROLLER_MANAGER_ARGS: '--root-ca-file=/srv/kubernetes/ca.pem --service-account-private-key-file=/srv/kubernetes/apiserver-key.pem'
    )
    action :create
    notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-controller-manager]', :immediately
  end

  %w(kube-apiserver kube-controller-manager).each do |svc|
    service "Enable #{svc}" do
      service_name svc
      action :enable
    end

    # This adds each custom service resource to the collection in the correct
    # order, and register only those that are affeted by changes upon notification
    kubernetes_chef_cookbook_service svc do
      action :nothing
    end
  end

  kubernetes_chef_cookbook_service 'systemctl daemon-reload' do
    action :nothing
  end
end
