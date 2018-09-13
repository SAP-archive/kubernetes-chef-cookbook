#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: common
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

if node[cookbook_name]['cluster_id'].nil?
  abort("No cluster_id defined. Please define a cluster_id in the node's attributes (regardless if master or node). This needs to match the role name. See README.md.")
end

unless %w(source vendor).include?(node[cookbook_name]['installation_method'])
  abort("Installation method #{node[cookbook_name]['installation_method']} not supported.")
end

if node[cookbook_name]['kubernetes']['version'] == 'latest'
  require 'mixlib/shellout'
  kube_version = Mixlib::ShellOut.new('curl https://storage.googleapis.com/kubernetes-release/release/stable.txt')
  kube_version.run_command
  node.normal[cookbook_name]['kubernetes']['repository'] = "https://storage.googleapis.com/kubernetes-release/release/#{kube_version.stdout.strip}/bin/linux/amd64"
  node.normal[cookbook_name]['kubernetes']['version'] = kube_version.stdout.strip
end

unless %w(flannel).include?(node[cookbook_name]['kubernetes']['cni'])
  abort("CNI #{node[cookbook_name]['cni']} not supported.")
end

node[cookbook_name]['plugins'].each do |plugin|
  unless %w(kube-dns dashboard monitoring helm).include?(plugin)
    abort("The plugin #{plugin} is currently not supported.")
  end
end

if node[cookbook_name]['plugins'].include?('dashboard') && !node[cookbook_name]['plugins'].include?('kube-dns')
  abort('The dashboard plugin needs kube-dns. Please add it!')
end

if !(node[cookbook_name]['root_ca']['ca'].empty? && node[cookbook_name]['root_ca']['ca_key'].empty?)
  node.default[cookbook_name]['root_ca']['root_ca_installation_method'] = 'url'
elsif 0 == 1
  # TODO: Implement
  node.default[cookbook_name]['root_ca']['root_ca_installation_method'] = 'databag'
else
  abort('Please provide a location for the root ca and the root ca key')
end

# If the ohai plugin 'passwd' is disabled, the following if statement would crash. Thus we test.
if !node['etc'].nil? && !node['etc']['passwd'].nil? && node['etc']['passwd']['vagrant'] && node['virtualization']['system'] == 'vbox'
  node.default[cookbook_name]['flannel']['standard_interface'] = node['network']['interfaces']['eth1'].nil? ? 'enp0s8' : 'eth1'
  Chef::Log.warn('It seems you are running on Vagrant. Adjusting flannels standard interface.')
end

# NOTE: This is only used in test kitchen as private IPs in AWS are not freed quickly enough
# for sequential testing
if test_kitchen_active? && node[cookbook_name]['test_kitchen']['master'] == 'true'
  node.normal[cookbook_name]['masters'] = [{ name: 'master1', ip: node['ipaddress'] }]
  node.normal[cookbook_name]['kubernetes']['virtual_api_server_ip'] = node['ipaddress']
end
