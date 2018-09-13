require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]
node_system = nodes[:node_system]

control 'etcd' do
  title 'Verify the etcd installation'

  describe user('etcd') do
    it { should exist }
    its('group') { should include 'etcd' }
    its('shell') { should eq '/bin/false' }
    its('home') { should eq '/var/lib/etcd' }
  end

  describe directory('/var/lib/etcd') do
    it { should exist }
    its('owner') { should eq 'etcd' }
  end

  describe file('/etc/etcd/etcd.conf') do
    its('content') { should include 'ETCD_INITIAL_ADVERTISE_PEER_URLS="http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2380"' }
    its('content') { should include 'ETCD_ADVERTISE_CLIENT_URLS="http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2379"' }
    its('content') { should include 'ETCD_INITIAL_CLUSTER="master1=http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2380"' }
  end

  describe service('etcd') do
    it { should be_enabled }
    it { should be_running }
  end

  # Disabling until inspec version gets updated
  # describe http('http://127.0.0.1:2379/version', enable_remote_worker: true) do
  #   its('body') { should include '"etcdserver":"' + node[cookbook_name]['etcd']['source_version'].delete('v') + '"' }
  # end

  describe command("etcdctl get #{node[cookbook_name]['flannel']['etcd_prefix']}/config") do
    its('stdout').to_json { should include ({
          "Network": node[cookbook_name]['flannel']['subnet'],
          "SubnetLen": 24,
          "Backend": {
              "Type": "vxlan"
          }
        }
      )
    }
  end
end
