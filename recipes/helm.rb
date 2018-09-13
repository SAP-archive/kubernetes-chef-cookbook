#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: helm
#
# Copyright:: 2017, DevOps CoE, Internal use only.

kubernetes_chef_cookbook_helm 'kubernetes-helm' do
  action :configure
  repository node[cookbook_name]['helm']['repository']
  source_version node[cookbook_name]['helm']['version']
  only_if { node[cookbook_name]['kube_info']['role'] == 'master' }
end
