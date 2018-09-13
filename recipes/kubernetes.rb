kube_info = node[cookbook_name]['kube_info']
role = kube_info['role']
kubernetes_version_adjusted = node[cookbook_name]['kubernetes']['version'].delete('v')

kubernetes 'main' do
  action :install
  additional_packages node[cookbook_name]['kubernetes']["#{kube_info['role']}_packages"]
  installation_method node[cookbook_name]['installation_method']
  repository node[cookbook_name]['kubernetes']['repository']
  kubernetes_version kubernetes_version_adjusted
  role role
  target_platform node['platform']
end

kubernetes 'config' do
  action :configure
  etcd_cluster_ips node[cookbook_name]['etcd']['cluster_ips']
  instance_ip node['ipaddress']
  kube_ip_range node[cookbook_name]['kubernetes']['kube_ip_range']
  role role
  root_ca_installation_method node[cookbook_name]['root_ca']['root_ca_installation_method']
  root_ca_repository node[cookbook_name]['root_ca']['ca']
  root_ca_key_repository node[cookbook_name]['root_ca']['ca_key']
  services node[cookbook_name]['kubernetes']["#{kube_info['role']}_services"]
  target_platform node['platform']
  virtual_api_server_ip node[cookbook_name]['kubernetes']['virtual_api_server_ip']
end

kubernetes 'config_minion' do
  action :configure_minion
  cgroup_driver node[cookbook_name]['kubernetes']['cgroup_driver']
  cluster_name node[cookbook_name]['cluster_id']
  instance_ip node['ipaddress']
  target_platform node['platform']
  virtual_api_server_ip node[cookbook_name]['kubernetes']['virtual_api_server_ip']
  only_if { kube_info['role'] == 'minion' }
end

kubernetes 'config_master' do
  action :configure_master
  etcd_cluster_ips node[cookbook_name]['etcd']['cluster_ips']
  instance_ip node['ipaddress']
  kube_ip_range node[cookbook_name]['kubernetes']['kube_ip_range']
  kube_service_ip node[cookbook_name]['kubernetes']['kube_service_ip']
  role role
  target_platform node['platform']
  virtual_api_server_ip node[cookbook_name]['kubernetes']['virtual_api_server_ip']
  only_if { kube_info['role'] == 'master' }
end
