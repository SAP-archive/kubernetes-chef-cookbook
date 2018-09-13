require_relative '../spec_helper'
cookbook_name = 'kubernetes_chef_cookbook'
nodes = nodes()
node = nodes[:node]

control 'docker' do
  title 'Verify the basic network setup for kubernetes'

  docker_network_id = inspec.command('sudo docker network ls | grep "bridge"').stdout.match(/\w*/)
  flannel_mtu = inspec.command('cat /run/flannel/subnet.env | grep "MTU"').stdout.split('=').last.strip
  flannel_subnet = inspec.command('cat /run/flannel/subnet.env | grep "SUBNET"').stdout.split('=').last.strip

  describe command("sudo docker network inspect #{docker_network_id}") do
    its('stdout') { should include '"com.docker.network.driver.mtu": "' + flannel_mtu + '"' }
    its('stdout') { should include '"Subnet": "' + flannel_subnet + '"' }
  end

  if File.exist?('/etc/kubernetes/kubelet')
    describe command('sudo docker info') do
      its('stdout') { should include "Cgroup Driver: #{node[cookbook_name]['kubernetes']['cgroup_driver']}" }
    end
  end
end
