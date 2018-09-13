#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: hosts
#
# Copyright:: 2017, SAP DevOps CoE, All Rights Reserved.
kube_info = node[cookbook_name]['kube_info']
role = kube_info['role']

# Create cluster entries in hosts file
cluster_entries = ''
kube_info['cluster'].each do |member|
  host = member[:name].split('.')[0] # ensures that this is just the hostname, without any domain info
  cluster_entries += "#{member[:ip]} #{host}\n"
end

cluster_entries += node[cookbook_name]['additional_host_entries'] unless node[cookbook_name]['additional_host_entries'].nil?

directory '/etc/cloud/templates' do
  action :create
  recursive true
  not_if { ::File.directory?('/etc/cloud/templates') }
end

%w(/etc/hosts /etc/cloud/templates/hosts.redhat.tmpl).each do |host_file|
  template host_file do
    source 'hosts.erb'
    variables(
      host_entries: cluster_entries
    )
    action :create
    notifies :register_restart, 'kubernetes_chef_cookbook_service[systemctl daemon-reload]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[docker]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-apiserver]', :immediately if role == 'master'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-controller-manager]', :immediately if role == 'master'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-scheduler]', :immediately if role == 'master'
    notifies :register_restart, 'kubernetes_chef_cookbook_service[flanneld]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kube-proxy]', :immediately
    notifies :register_restart, 'kubernetes_chef_cookbook_service[kubelet]', :immediately
  end
end

['systemctl daemon-reload', 'docker', 'kube-apiserver', 'kube-controller-manager', 'kube-scheduler', 'flanneld', 'kube-proxy', 'kubelet'].each do |svc|
  kubernetes_chef_cookbook_service svc do
    action :nothing
  end
end
