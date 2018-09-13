platform = node['platform']

docker 'docker' do
  action :install
  installation_method node[cookbook_name]['installation_method']
  platform_distribution node['lsb']['codename'] unless node['lsb']['codename'].nil?
  docker_name node[cookbook_name]['docker']['package_name'][platform]
  target_platform platform
  vendor_version node[cookbook_name]['docker']['vendor_version'][platform] unless node[cookbook_name]['docker']['vendor_version'][platform].nil?
  source_version node[cookbook_name]['docker']['source_version'][platform] unless node[cookbook_name]['docker']['source_version'][platform].nil?
end
