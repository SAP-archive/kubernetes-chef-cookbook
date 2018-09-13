#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: default
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.
ohai_plugin 'Vboxipaddress'

include_recipe "#{cookbook_name}::preflight_checks"

# Disable swap since kubelet can't deal with it and we should not introduce
# changes between dev and prod
swapoff = Mixlib::ShellOut.new("swapoff -a &&  sudo sed -i '/ swap / s/^/#/' /etc/fstab")
swapoff.run_command

case node['platform']
when 'ubuntu'
  execute 'update apt' do
    command 'apt-get update'
  end
end

node[cookbook_name]['common_packages'].each do |pkg|
  package pkg do
    action :install
  end
end

node.default[cookbook_name]['kube_info'] = kube
role = node[cookbook_name]['kube_info']['role']

Log.fatal err('no_role') unless role

if node[cookbook_name]['etcd']['cluster_ips'].empty?
  node.default[cookbook_name]['etcd']['cluster_ips'] = kube['masters']
  node.default[cookbook_name]['etcd']['use_masters'] = 'true'
end
abort('No etcd cluster ips. Failing!') if node[cookbook_name]['etcd']['cluster_ips'].empty?

if node[cookbook_name]['kubernetes']['virtual_api_server_ip'].nil? || node[cookbook_name]['kubernetes']['virtual_api_server_ip'].empty?
  node.default[cookbook_name]['kubernetes']['virtual_api_server_ip'] = kube['masters'].first[:ip]
end
abort('No virtual api server ip set. Failing!') if node[cookbook_name]['kubernetes']['virtual_api_server_ip'].nil? || node[cookbook_name]['kubernetes']['virtual_api_server_ip'].empty?

include_recipe "#{cookbook_name}::#{role}"

kubernetes_chef_cookbook_service 'Restart pending services to complete installation' do
  delay_execution false
  action :restart_pending_services
end

if role == 'master'
  # Make sure kube-dns always gets installed first
  include_recipe "#{cookbook_name}::kube-dns" if node[cookbook_name]['plugins'].include?('kube-dns')

  # Now install all the other plugins
  node[cookbook_name]['plugins'].each do |plugin|
    include_recipe "#{cookbook_name}::#{plugin}" unless plugin == 'kube-dns'
  end
end
