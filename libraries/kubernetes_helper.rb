module KubernetesHelper
  def yum_role(role)
    role == 'master' ? 'master' : 'node'
  end

  def installed_kubernetes_version
    if node[cookbook_name]['kubernetes']['final_installation_method'] == 'vendor'
      case target_platform
      when 'centos', 'redhat' # ~FC024 Foodcritic recognizes here that we are doing a OS recognition, but expects exotic OS to be added as well
        version = Mixlib::ShellOut.new("yum info kubernetes-#{yum_role(role)}")
        version.run_command
        vendor_kubernetes = version.stdout
        return vendor_kubernetes.match(/Version\s*:\s(\d+\.)+\d+/).to_s.match(/(\d+\.)+\d+/).to_s
      end
    end

    node[cookbook_name]['kubernetes']['version'].delete('v')
  end
end
