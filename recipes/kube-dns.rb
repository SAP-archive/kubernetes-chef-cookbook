#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: kube-dns
#
# Copyright:: 2017, The Authors, All Rights Reserved.
kubernetes_chef_cookbook_kube_dns node[cookbook_name]['kube-dns']['cluster_ip'] do
  role node[cookbook_name]['kube_info']['role']
  service_name 'kube-dns'
  action :configure
end
