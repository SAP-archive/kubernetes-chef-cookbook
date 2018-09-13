# Basic configuration
default['kubernetes_chef_cookbook']['proxy'] = ENV['http_proxy']
default['kubernetes_chef_cookbook']['proxy_exceptions'] = 'localhost, 127.0.0.1'
default['kubernetes_chef_cookbook']['config_version_threshold'] = '1.8.0'
default['kubernetes_chef_cookbook']['installation_method'] = 'source' # vendor / source
default['kubernetes_chef_cookbook']['common_packages'] = %w(conntrack socat)
default['kubernetes_chef_cookbook']['additional_host_entries'] = ''

# Cluster configuration
default['kubernetes_chef_cookbook']['masters'] = {}
default['kubernetes_chef_cookbook']['minions'] = {}
default['kubernetes_chef_cookbook']['plugins'] = ['kube-dns', 'dashboard', 'monitoring', 'helm'] # kube-dns, dashboard, monitoring

# Location of root ca
default['kubernetes_chef_cookbook']['root_ca']['ca'] = ''
default['kubernetes_chef_cookbook']['root_ca']['ca_key'] = ''

# Kubernetes configuration
default['kubernetes_chef_cookbook']['kubernetes']['version'] = 'latest'
default['kubernetes_chef_cookbook']['kubernetes']['repository'] = "https://storage.googleapis.com/kubernetes-release/release/#{node['kubernetes_chef_cookbook']['kubernetes']['version']}/bin/linux/amd64"
default['kubernetes_chef_cookbook']['kubernetes']['master_services'] = %w(kube-apiserver kube-controller-manager kube-scheduler)
default['kubernetes_chef_cookbook']['kubernetes']['minion_services'] = %w(kubelet kube-proxy)
default['kubernetes_chef_cookbook']['kubernetes']['master_packages'] = %w(kube-apiserver kube-controller-manager kubectl kube-scheduler)
default['kubernetes_chef_cookbook']['kubernetes']['minion_packages'] = %w(kubectl kubelet kube-proxy)
default['kubernetes_chef_cookbook']['kubernetes']['cni'] = 'flannel'
# This IP is equivalent to the virtual IP used by keepalived
default['kubernetes_chef_cookbook']['kubernetes']['virtual_api_server_ip'] = ''
# choose any IP range make sure it does not overlap with any other IP range
default['kubernetes_chef_cookbook']['kubernetes']['kube_ip_range'] = '10.254.0.0/16'
# First IP from service cluster IP range is always allocated to Kubernetes Service
default['kubernetes_chef_cookbook']['kubernetes']['kube_service_ip'] = '10.254.0.1'
# Kubernetes Infra subnet
default['kubernetes_chef_cookbook']['kubernetes']['subnet'] = '10.58.122.0/23'
# Which cgroup driver to use for kubelet and docker
default['kubernetes_chef_cookbook']['kubernetes']['cgroup_driver'] = 'cgroupfs'

# Docker configuration
default['kubernetes_chef_cookbook']['docker']['vendor_version']['ubuntu'] = '17.12.0~ce-0~ubuntu'
default['kubernetes_chef_cookbook']['docker']['vendor_version']['redhat'] = '1.12.6-71.git3e8e77d.el7'
default['kubernetes_chef_cookbook']['docker']['vendor_version']['centos'] = '1.12.6-71.git3e8e77d.el7'
default['kubernetes_chef_cookbook']['docker']['source_version']['ubuntu'] = '17.12.0~ce-0~ubuntu'
default['kubernetes_chef_cookbook']['docker']['source_version']['redhat'] = '17.12.0.ce-1.el7'
default['kubernetes_chef_cookbook']['docker']['source_version']['centos'] = '17.12.0.ce-1.el7'
default['kubernetes_chef_cookbook']['docker']['package_name']['ubuntu'] = 'docker-ce'
# In case of RedHat and CentOS the name for docker from extra, is docker.
# When installed from source (or fallback) official ce-version would be installed
# -ce is added automatically in this case.
default['kubernetes_chef_cookbook']['docker']['package_name']['redhat'] = 'docker'
default['kubernetes_chef_cookbook']['docker']['package_name']['centos'] = 'docker'
default['kubernetes_chef_cookbook']['docker']['subnet'] = '172.17.0.0/24' # Depends on Docker version

# Flannel configuration
default['kubernetes_chef_cookbook']['flannel']['source_version'] = 'v0.10.0'
default['kubernetes_chef_cookbook']['flannel']['vendor_version']['redhat'] = '0.7.1-2.el7'
default['kubernetes_chef_cookbook']['flannel']['vendor_version']['centos'] = '0.7.1-2.el7'
default['kubernetes_chef_cookbook']['flannel']['repository'] = "http://github.com/coreos/flannel/releases/download/#{node['kubernetes_chef_cookbook']['flannel']['source_version']}/flannel-#{node['kubernetes_chef_cookbook']['flannel']['source_version']}-linux-amd64.tar.gz"
default['kubernetes_chef_cookbook']['flannel']['etcd_prefix'] = '/kube-glds/network'
default['kubernetes_chef_cookbook']['flannel']['subnet'] = '172.17.0.0/16' # choose any IP range just make sure it does not overlap with any other IP range
default['kubernetes_chef_cookbook']['flannel']['standard_interface'] = nil # NOTE: Do not touch this if you do not know what it does!

# etcd configuration
default['kubernetes_chef_cookbook']['etcd']['source_version'] = 'v3.3.0'
default['kubernetes_chef_cookbook']['etcd']['vendor_version']['redhat'] = '3.2.11-1.el7'
default['kubernetes_chef_cookbook']['etcd']['vendor_version']['centos'] = '3.2.11-1.el7'
default['kubernetes_chef_cookbook']['etcd']['repository'] = "http://github.com/coreos/etcd/releases/download/#{node['kubernetes_chef_cookbook']['etcd']['source_version']}/etcd-#{node['kubernetes_chef_cookbook']['etcd']['source_version']}-linux-amd64.tar.gz"
default['kubernetes_chef_cookbook']['etcd']['cluster_ips'] = [] # [{ name: '', ip: ''}, { name: '', ip: '' }]

# kube-dns configuration
default['kubernetes_chef_cookbook']['kube-dns']['cluster_ip'] = '10.254.0.2'
default['kubernetes_chef_cookbook']['kube-dns']['cluster_domain'] = 'cluster.local'

# Helm conifguration
default['kubernetes_chef_cookbook']['helm']['version'] = 'v2.8.1'
default['kubernetes_chef_cookbook']['helm']['repository'] = "https://storage.googleapis.com/kubernetes-helm/helm-#{node['kubernetes_chef_cookbook']['helm']['version']}-linux-amd64.tar.gz"
