require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]
node_system = nodes[:node_system]

kubernetes_version = inspec.command('kubectl version').stdout.match(/GitVersion:"v\d+.\d+.\d+"/).to_s.split(':').last.delete('v').delete('"')

# NOTE: These tests are only used in the local development environment!
control 'kubernetes' do
  title 'Verify the basic kubernetes installation for the minion node'

  node[cookbook_name]['kubernetes']['minion_services'].each do |svc|
    describe service(svc) do
      it { should be_installed }
      it { should be_enabled }
    end
  end

  node[cookbook_name]['kubernetes']['minion_packages'].each do |pkg|
    describe file("/usr/bin/#{pkg}") do
      it { should exist }
    end
  end

  if Gem::Version.new(kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    %w(ca-key.pem ca.pem ca.srl kube-proxy-key.pem kube-proxy.pem worker-key.pem worker.pem).each do |cert|
      describe file("/srv/kubernetes/#{cert}") do
        it { should exist }
      end
    end
  else
    describe directory('/srv/kubernetes') do
      it { should_not exist }
    end
  end

  describe file('/etc/kubernetes/config') do
    it { should exist }
    its('content') { should include 'KUBE_ETCD_SERVERS="--etcd-servers=http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2379"' }
    its('content') { should include 'KUBE_MASTER="--master=http://' + node[cookbook_name]['kube_info']['masters'][0]['ip'] + ':8080"' }
  end

  describe file('/etc/kubernetes/kubelet') do
    it { should exist }
    its('content') { should include 'KUBELET_HOSTNAME="--hostname-override=' + node_system['ipaddress'] + '"' }
  end

  if Gem::Version.new(kubernetes_version) < Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    describe file('/etc/kubernetes/kubelet') do
      its('content') { should include 'KUBELET_API_SERVER="--api-servers=http://' + node[cookbook_name]['kube_info']['masters'][0]['ip'] + ':8080"' }
    end
  else
    describe file('/etc/kubernetes/kubelet') do
      its('content') { should include 'KUBE_CONFIG="--kubeconfig=/etc/kubernetes/worker.kubeconfig"' }
      its('content') { should include 'KUBELET_DNS="--cluster-dns=10.254.0.2"' }
      its('content') { should include 'KUBELET_DOMAIN="--cluster-domain=cluster.local"' }
    end
  end

  if Gem::Version.new(kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    describe file('/etc/kubernetes/worker.kubeconfig') do
      it { should exist }
      its('content') { should include 'server: https://' + node[cookbook_name]['kube_info']['masters'][0]['ip'] + ':6443' }
      its('content') { should include 'user: system:node:worker' }
      its('content') { should include 'cluster: aaaa' }
    end
  end

  if Gem::Version.new(kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    describe file('/etc/kubernetes/kube-proxy.kubeconfig') do
      it { should exist }
      its('content') { should include "server: https://#{node[cookbook_name]['kube_info']['masters'][0]['ip']}:6443" }
      its('content') { should include "cluster: #{node[cookbook_name]['cluster_id']}" }
      its('content') { should include 'user: kube-proxy' }
    end
  end
end
