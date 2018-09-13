#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: master
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

# Only adjust that in test kitchen, but otherwise flanneld will not start and we can not
# test the minion without master
if test_kitchen_active? && node[cookbook_name]['kube_info']['role'] == 'minion'
  node.default[cookbook_name]['etcd']['cluster_ips'] = [{ name: 'minion1', ip: node['ipaddress'] }]
end

platform = node['platform']

etcd 'etcd' do
  action :install
  installation_method node[cookbook_name]['installation_method']
  repository node[cookbook_name]['etcd']['repository']
  target_platform platform
  source_version node[cookbook_name]['etcd']['source_version']
  vendor_version node[cookbook_name]['etcd']['vendor_version'][platform] unless node[cookbook_name]['etcd']['vendor_version'][platform].nil?
end

etcd 'configure' do
  action :configure
  cluster_ips node[cookbook_name]['etcd']['cluster_ips']
  hostname node['hostname']
  local_etcd_ips [{ name: node['hostname'], ip: node['ipaddress'] }]
end
