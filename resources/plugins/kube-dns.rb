# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
property :cluster_ip, String, name_property: true
property :role, String
property :service_name, String, default: 'kube-dns'

def cache
  Chef::Config[:file_cache_path]
end

load_current_value do |new_resource|
  # Check the service_name attribute
  if new_resource.role == 'master'
    require 'mixlib/shellout'
    kube_status = Mixlib::ShellOut.new('kubectl get po,svc,rc -n kube-system')
    kube_status.run_command
    # # kube-dns is in the desired state if stdout includes the service name
    service_name kube_status.stdout[new_resource.service_name].to_s
  else
    # prevent resource from being triggered for minions (resource would be triggered with no actions)
    service_name new_resource.service_name
  end

  # Check the cluster_ip attribute
  if ::File.exist?('/etc/kubernetes/kubelet')
    cluster_ip ::File.read('/etc/kubernetes/kubelet')[/(?<=--cluster-dns=)(((\d){1,3}\.){3})(\d{1,3})/].to_s
  end

  # Prevent the role from triggering the resource
  role new_resource.role
end

action :configure do
  converge_if_changed :service_name do
    # load files (with variables)
    directory ::File.join(cache, 'kube-dns') do
      recursive true
      action :create
    end

    %w(svc rc).each do |file|
      template ::File.join(cache, 'kube-dns', "kube-dns-#{file}.yaml") do
        source "kube-dns-#{file}.yaml.erb"
        variables(
          clusterip: new_resource.cluster_ip,
          service_name: new_resource.service_name
        )
        action :create
      end
    end

    # execute installation and remove files
    execute 'kubectl create -f kube-dns' do
      cwd cache
      action :run
      notifies :delete, "directory[#{::File.join(cache, 'kube-dns')}]"
    end
  end # end of dns installation
end
