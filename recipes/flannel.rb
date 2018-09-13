role = node[cookbook_name]['kube_info']['role']
platform = node['platform']

flannel 'flannel_install' do
  action :install
  installation_method node[cookbook_name]['installation_method']
  target_platform platform
  repository node[cookbook_name]['flannel']['repository']
  source_version node[cookbook_name]['flannel']['source_version']
  vendor_version node[cookbook_name]['flannel']['vendor_version'][platform] unless node[cookbook_name]['flannel']['vendor_version'][platform].nil?
end

flannel 'flannel_configure' do
  action :configure
  etcd_cluster_ips node[cookbook_name]['etcd']['cluster_ips']
  etcd_prefix node[cookbook_name]['flannel']['etcd_prefix']
  flannel_interface node[cookbook_name]['flannel']['standard_interface'] unless node[cookbook_name]['flannel']['standard_interface'].nil? || node[cookbook_name]['flannel']['standard_interface'].empty?
  flannel_subnet node[cookbook_name]['flannel']['subnet']
  role role
  target_platform node['platform']
end
