module EtcdHelper
  def get_etcd_server_urls(etcd_local_ips, port = 2379)
    kube_etcd_servers = ''
    etcd_local_ips.each_with_index do |member, index|
      kube_etcd_servers += "http://#{member[:ip]}:#{port}"
      kube_etcd_servers += ',' unless index == etcd_local_ips.size - 1
    end
    kube_etcd_servers
  end

  def get_etcd_cluster_urls(etcd_cluster_ips, port = 2380)
    kube_etcd_servers = ''
    etcd_cluster_ips.each_with_index do |member, index|
      kube_etcd_servers += "#{member[:name]}=http://#{member['ip']}:#{port}"
      kube_etcd_servers += ',' unless index == etcd_cluster_ips.size - 1
    end
    kube_etcd_servers
  end

  def get_etcd_name(cluster_ips)
    cluster_ips.each do |member|
      return member['name'] if member['ip'] == node['ipaddress']
    end
  end
end
