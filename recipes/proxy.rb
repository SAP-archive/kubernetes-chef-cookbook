#
# Cookbook:: kubernetes_chef_cookbook
# Recipe:: proxy
#
# Copyright:: 2017, SAP DevOps CoE, All Rights Reserved.

kube_info = node[cookbook_name]['kube_info']

# Setup the base proxy exception list
proxy_exception = node[cookbook_name]['proxy_exceptions']

# Add each cluster member's IP to the list
kube_info['cluster'].each do |_host, ip|
  proxy_exception += ",#{ip}"
end

proxy_settings = {
  http_proxy: node[cookbook_name]['proxy'],
  HTTP_PROXY: node[cookbook_name]['proxy'],
  https_proxy: node[cookbook_name]['proxy'],
  HTTPS_PROXY: node[cookbook_name]['proxy'],
  ftp_proxy: node[cookbook_name]['proxy'],
  FTP_PROXY: node[cookbook_name]['proxy'],
  no_proxy: proxy_exception,
  NO_PROXY: proxy_exception,
}

# Apply the proxy settings right now
proxy_settings.each { |k, v| ENV[k.to_s] = v }

# Apply the proxy settings globally
template '/etc/environment' do
  source 'environment.erb'
  variables proxy_settings
  action :create
end
