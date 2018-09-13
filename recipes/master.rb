#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: master
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

# Install etcd locally on the masters if no cluster ips are specified
include_recipe "#{cookbook_name}::etcd" if node[cookbook_name]['etcd']['use_masters'] == 'true'

# I do everything the minion does and more :) - decided by role, executed in kubernetes resource
include_recipe "#{cookbook_name}::minion"
