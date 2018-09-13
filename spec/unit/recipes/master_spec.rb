#
# Cookbook:: kubernetes_chef_cookbook
# Spec:: default
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

require 'spec_helper'

describe 'kubernetes_chef_cookbook::master' do
  context 'When the node is RHEL 7.3  on monsoon2' do
    let(:chef_run) do
      ChefSpec::ServerRunner.new(platform: 'redhat', version: '7.3') do |node|
        node.automatic['hostname'] = 'chefspec-host'
        node.default['monsoon']['instances']['chefspec-host']['tags']['kubernetes'] = type
      end.converge(described_recipe)
    end

    it 'includes all the common requirements recipe' do
      expect(chef_run).to include_recipe('kubernetes_chef_cookbook::common')
    end

    it 'creates the etcd config from a template' do
      expect(chef_run).to create_template('/etc/etcd/etcd.conf')
    end
  end
end
