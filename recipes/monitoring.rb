#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: dashboard
#
# Copyright:: 2017, DevOps CoE, Internal use only.
kubernetes_chef_cookbook_monitoring 'Grafana-InfluxDB' do
  action :configure
  execute_install true
  only_if { node[cookbook_name]['kube_info']['role'] == 'master' }
end
