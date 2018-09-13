require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]

control 'plugins' do
  title 'Verify the basic plugin deployment for the master node'
  describe command('kubectl get po,svc,rc -n kube-system') do
    node[cookbook_name]['plugins'].each do |plugin|
      plugin = 'tiller' if plugin == 'helm'
      its('stdout') { should match(%r{po\/.*#{plugin}.*}) }
      its('stdout') { should match(%r{svc\/.*#{plugin}.*}) }
    end
  end
end
