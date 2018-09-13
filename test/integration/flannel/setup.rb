require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]

control 'flannel' do
  title 'Verify the basic flannel installation'

  describe file('/usr/bin/flanneld') do
    it  { should exist }
  end

  describe file('/etc/kubernetes/flanneld') do
    it  { should exist }
    its('content') { should include 'FLANNEL_ETCD_ENDPOINTS="--etcd-endpoints=http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2379"' }
    its('content') { should include 'FLANNEL_ETCD_PREFIX="--etcd-prefix=' + node[cookbook_name]['flannel']['etcd_prefix'] + '"' }
  end

  describe service('flanneld') do
    it { should be_installed }
    it { should be_enabled }
  end

  describe bash('flanneld -version | tr -d "\n"') do
    # For some reason flanneld uses stderr as output
    its('stderr') { should include node[cookbook_name]['flannel']['source_version'] }
  end
end
