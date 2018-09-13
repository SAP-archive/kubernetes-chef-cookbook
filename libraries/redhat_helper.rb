module RedhatHelper
  def extras_active?
    repolist = Mixlib::ShellOut.new('yum repolist')
    repolist.run_command
    repolist.stdout.include?('extras')
  end

  def enable_redhat_extras
    yum_repository 'rhel-7-server-extras-rpms' do
      action :create
      not_if { extras_active? }
      sensitive false
    end
  end
end
