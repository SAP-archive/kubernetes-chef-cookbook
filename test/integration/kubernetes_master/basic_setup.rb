require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]
kubernetes_version = inspec.command('kubectl version').stdout.match(/GitVersion:"v\d+.\d+.\d+"/).to_s.split(':').last.delete('v').delete('"')

control 'kubernetes' do
  title 'Verify the basic kubernetes installation for the master node'

  node[cookbook_name]['kubernetes']['master_services'].each do |svc|
    describe service(svc) do
      it { should be_installed }
      it { should be_enabled }
    end
  end

  node[cookbook_name]['kubernetes']['master_packages'].each do |pkg|
    describe file("/usr/bin/#{pkg}") do
      it { should exist }
    end
  end

  %w(ca.pem apiserver.pem apiserver-key.pem).each do |cert_file|
    describe file("/srv/kubernetes/#{cert_file}") do
      it { should exist }
    end
  end

  if Gem::Version.new(kubernetes_version) >= Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    describe file('/srv/kubernetes/ca-key.pem') do
      it { should exist }
    end
  end

  describe file('/etc/kubernetes/apiserver') do
    it { should exist }
    its('content') { should include 'KUBE_ETCD_SERVERS="--etcd-servers=http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2379"' }
    its('content') { should include 'KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.254.0.0/16"' }
  end

  if Gem::Version.new(kubernetes_version) < Gem::Version.new(node[cookbook_name]['config_version_threshold'])
    describe file('/etc/kubernetes/apiserver') do
      its('content') { should include 'KUBE_API_ADDRESS="--address=0.0.0.0"' }
      its('content') { should include 'KUBE_API_PORT="--port=8080"' }
      its('content') { should include 'KUBELET_PORT="--kubelet-port=10250"' }
    end
  else
    describe file('/etc/kubernetes/apiserver') do
      its('content') { should include 'KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"' }
      its('content') { should include 'KUBE_API_PORT="--insecure-port=8080"' }
      its('content') { should_not include 'KUBELET_PORT="--kubelet-port=10250"' }
    end
  end

  describe file('/etc/kubernetes/controller-manager') do
    it { should exist }
    its('content') { should include 'KUBE_CONTROLLER_MANAGER_ARGS="--root-ca-file=/srv/kubernetes/ca.pem --service-account-private-key-file=/srv/kubernetes/apiserver-key.pem"' }
  end

  describe file('/etc/kubernetes/config') do
    it { should exist }
    its('content') { should include 'KUBE_ETCD_SERVERS="--etcd-servers=http://' + node[cookbook_name]['etcd']['cluster_ips'][0]['ip'] + ':2379"' }
    its('content') { should include 'KUBE_MASTER="--master=http://' + node[cookbook_name]['kube_info']['masters'].first['ip'] + ':8080"' }
  end

  describe command('kubectl get componentstatuses') do
    its('stdout') { should include 'controller-manager   Healthy   ok' }
    its('stdout') { should include 'scheduler            Healthy   ok' }
    its('stdout') { should include 'etcd-0               Healthy   {"health":"true"}' }
  end
end
