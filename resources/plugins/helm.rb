# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
property :service_name, String, name_property: true
property :repository, String
property :source_version, String

def cache
  Chef::Config[:file_cache_path]
end

load_current_value do |new_resource|
  # Check the service_name attribute
  require 'mixlib/shellout'
  helm_status = Mixlib::ShellOut.new('kubectl get pod,svc,rc,rs,deploy,ds --all-namespaces')
  helm_status.run_command
  # helm is installed if stdout includes the service name
  service_name helm_status.stdout[new_resource.service_name].to_s
end

action :configure do
  converge_if_changed :service_name do
    remote_file 'download_helm' do
      path "#{Chef::Config[:file_cache_path]}/helm-#{new_resource.source_version}-linux-amd64.tar.gz"
      action :create
      source new_resource.repository
      mode '0755'
      notifies :run, 'execute[untar_helm]', :immediately
    end

    execute 'untar_helm' do
      command "tar -xzvf #{Chef::Config[:file_cache_path]}/helm-#{new_resource.source_version}-linux-amd64.tar.gz -C #{Chef::Config[:file_cache_path]}/ --strip 1"
      action :nothing
      notifies :run, 'execute[move_helm]', :immediately
    end

    execute 'move_helm' do
      command "mv #{Chef::Config[:file_cache_path]}/helm /usr/bin/helm"
      action :nothing
      notifies :run, 'execute[init_helm]', :immediately
    end

    execute 'init_helm' do
      command 'helm init'
      action :nothing
    end
  end # end of helm installation
end
