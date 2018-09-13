#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: dashboard
#
# Copyright:: 2017, DevOps CoE, Internal use only.

include_recipe "#{cookbook_name}::kube-dns"

kubernetes_chef_cookbook_dashboard 'kubernetes-dashboard' do
  action :configure
  only_if { node[cookbook_name]['kube_info']['role'] == 'master' }
end
