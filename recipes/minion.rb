#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: common
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

# Disable firewalld and iptables
%w(firewalld iptables).each do |svc|
  service svc do
    action [:stop, :disable]
  end
end

# Only install etcd on the minion1 when running in test kitchen, since flanneld
# would not start otherwise and we could not test the minion without the master
include_recipe "#{cookbook_name}::etcd" if test_kitchen_active?

include_recipe "#{cookbook_name}::proxy"

include_recipe "#{cookbook_name}::hosts"

include_recipe "#{cookbook_name}::docker"

include_recipe "#{cookbook_name}::kubernetes"

include_recipe "#{cookbook_name}::flannel"
