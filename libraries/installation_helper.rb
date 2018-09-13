module InstallationHelper
  def run_installation(package, target_platform, installation_method)
    case package
    when 'docker', 'docker-ce'
      supports_vendor_installation = %w(redhat centos).include?(target_platform)
      supports_source_installation = %w(centos ubuntu).include?(target_platform)
    when 'etcd'
      supports_vendor_installation = %w(redhat centos).include?(target_platform)
      supports_source_installation = %w(redhat centos ubuntu).include?(target_platform)
    when 'flannel'
      supports_vendor_installation = %w(redhat centos).include?(target_platform)
      supports_source_installation = %w(redhat centos ubuntu).include?(target_platform)
    when 'kubernetes'
      supports_vendor_installation = %w(redhat centos).include?(target_platform)
      supports_source_installation = %w(redhat centos ubuntu).include?(target_platform)
    else
      Chef::Log.fatal("Package #{package} is not supported.")
    end

    final_installation_method = ''
    if installation_method == 'vendor'
      if supports_vendor_installation
        final_installation_method = 'vendor'
        Chef::Log.info("Vendor installation of #{package} on #{target_platform}.")
        action_install_from_vendor()
      else
        final_installation_method = 'source'
        Chef::Log.fatal("#{package} can't be install from vendor on #{target_platform}, falling back to installation from source.")
        action_install_from_source()
      end
    elsif installation_method == 'source'
      if supports_source_installation
        final_installation_method = 'source'
        Chef::Log.info("Source installation of #{package} on #{target_platform}.")
        action_install_from_source()
      else
        final_installation_method = 'vendor'
        Chef::Log.fatal("#{package} can't be install from source on #{target_platform}, falling back to installation from vendor.")
        action_install_from_vendor()
      end
    end

    node.default[cookbook_name][package]['final_installation_method'] = final_installation_method
  end

  def package_available?(package, target_platform)
    case target_platform
    when 'redhat', 'centos' # ~FC024 Foodcritic recognizes here that we are doing a OS recognition, but expects exotic OS to be added as well
      command = 'yum list'
    when 'ubuntu'
      command = 'apt-cache dump'
    end
    availibility = Mixlib::ShellOut.new(command)
    availibility.run_command
    availibility.stdout.include?(package)
  end

  def version_available?(package, version, target_platform)
    case target_platform
    when 'redhat', 'centos' # ~FC024 Foodcritic recognizes here that we are doing a OS recognition, but expects exotic OS to be added as well
      command = "yum --showduplicates list #{package}"
    when 'ubuntu'
      command = "apt-cache madison #{package}"
    end
    availibility = Mixlib::ShellOut.new(command)
    availibility.run_command
    available = availibility.stdout.include?(version)
    if available
      Chef::Log.info("#{package} #{version} is available on #{target_platform}.")
      return true
    else
      Chef::Log.fatal("#{package} #{version} is not available on #{target_platform}. Using latest.")
      return false
    end
  end
end
