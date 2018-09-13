#
# Cookbook:: kubernetes_chef_cookbook
# Spec:: default
#
# Copyright:: 2018, SAP SE or an SAP affiliate company.

require 'spec_helper'

describe 'kubernetes_chef_cookbook::default' do
  %w(master minion none).each do |type|
    context "When the node is RHEL 7.3 with tag ['kubernetes']['#{type}'] on monsoon2" do
      let(:chef_run) do
        ChefSpec::ServerRunner.new(platform: 'redhat', version: '7.3') do |node|
          node.automatic['hostname'] = 'chefspec-host'
          node.default['monsoon']['instances']['chefspec-host']['tags']['kubernetes'] = type
        end.converge(described_recipe)
      end

      if type != 'none'
        it "includes the #{type} recipe" do
          expect(chef_run).to include_recipe("kubernetes_chef_cookbook::#{type}")
        end
        it 'converges successfully' do
          expect { chef_run }.to_not raise_error
        end
      else
        it 'doesn\'t include any recipes' do
          expect(chef_run).to_not include_recipe('kubernetes_chef_cookbook::master')
          expect(chef_run).to_not include_recipe('kubernetes_chef_cookbook::minion')
        end
      end
    end
  end
end
