#
# Cookbook:: kubernetes_chef_cookbook
# Spec:: default
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

require 'spec_helper'

describe 'kubernetes_chef_cookbook::common' do
  context 'When the node is RHEL 7.3  on monsoon2' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'redhat', version: '7.3') do |node|
        node.automatic['hostname'] = 'chefspec-host'
        node.default['monsoon']['instances']['chefspec-host']['tags']['kubernetes'] = type
      end.converge(described_recipe)
    end

    it 'installs required packages' do
      %w(kubernetes etcd flannel).each do |pkg|
        expect(chef_run).to install_package(pkg)
      end
    end

    it 'creates the kubernetes configuration from a template' do
      expect(chef_run).to create_template('/etc/kubernetes/config') # .with(
      # KUBE_ETCD_SERVERS: "--etcd-servers=http://#{master_ip}:2379",
      # KUBE_LOGTOSTDERR: '--logtostderr=true',
      # KUBE_LOG_LEVEL: '--v=0',
      # KUBE_ALLOW_PRIV: '--allow-privileged=false',
      # KUBE_MASTER: '--master=http://#{master_ip}:8080'
      # )
    end
  end
end
