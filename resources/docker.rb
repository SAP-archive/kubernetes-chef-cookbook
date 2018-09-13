# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
resource_name :docker

property :cgroup_driver, String
property :docker_name, String
property :installation_method, String
property :platform_distribution, String
property :target_platform, String
property :vendor_version, String
property :source_version, String

action_class do
  include InstallationHelper
  include RedhatHelper
end

action :install do
  run_installation(new_resource.docker_name, new_resource.target_platform, new_resource.installation_method)

  service 'docker' do
    action [:enable, :start]
  end
end

action :install_from_vendor do
  enable_redhat_extras() if new_resource.target_platform == 'redhat'

  # This is basically a fallback for RedHat where docker is usually available through
  # extra, but might fail. Hence, we'll fallback to source installation
  if !package_available?(new_resource.docker_name, new_resource.target_platform)
    Chef::Log.info("#{new_resource.docker_name} is not available on #{new_resource.target_platform}, falling back to installation from source.")
    action_install_from_source
  else
    package new_resource.docker_name do
      action :install
      version lazy { new_resource.vendor_version if version_available?(new_resource.docker_name, new_resource.vendor_version, new_resource.target_platform) }
    end
  end
end

action :install_from_source do
  case new_resource.target_platform
  when 'ubuntu'
    action_ubuntu_source_installation
  when 'centos'
    action_centos_source_installation
  else
    abort("#{new_resource.target_platform} is not supported. That means that docker is not available from the extras repository, or the extras repository could not be activated.")
  end
end

action :ubuntu_source_installation do
  apt_repository 'docker_repository' do
    uri 'https://download.docker.com/linux/ubuntu'
    key 'https://download.docker.com/linux/ubuntu/gpg'
    components ['stable']
    distribution new_resource.platform_distribution
    notifies :install, "package[install_#{new_resource.docker_name}_with_#{new_resource.vendor_version}]", :immediately
  end

  # Note: While this is the "source" installation, the "source_version" here is the vendor version
  # as an apt repository is used for installation (hence it is no "true" source installation)
  package "install_#{new_resource.docker_name}_with_#{new_resource.vendor_version}" do
    package_name new_resource.docker_name
    version lazy { new_resource.source_version if version_available?(new_resource.docker_name, new_resource.source_version, new_resource.target_platform) }
    action :nothing
  end
end

action :centos_source_installation do
  package 'yum-utils'

  execute 'configure docker repository' do
    command 'yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo'
  end

  package "install #{new_resource.docker_name}-ce from source" do
    package_name "#{new_resource.docker_name}-ce"
    version lazy { new_resource.source_version if version_available?(new_resource.docker_name, new_resource.source_version, new_resource.target_platform) }
  end
end
