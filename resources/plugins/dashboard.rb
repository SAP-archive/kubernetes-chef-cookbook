# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
property :service_name, String, name_property: true

def cache
  Chef::Config[:file_cache_path]
end

load_current_value do |new_resource|
  # Check the service_name attribute
  require 'mixlib/shellout'
  dash_status = Mixlib::ShellOut.new('kubectl get pod,svc,rc,rs,deploy,ds --all-namespaces')
  dash_status.run_command
  # dashboard is installed if stdout includes the service name
  service_name dash_status.stdout[new_resource.service_name].to_s
end

action :configure do
  converge_if_changed :service_name do
    # load files (with variables)
    directory ::File.join(cache, 'dashboard') do
      recursive true
      action :create
    end

    %w(controller service).each do |file|
      template ::File.join(cache, 'dashboard', "dashboard-#{file}.yaml") do
        source "dashboard-#{file}.yaml.erb"
        variables(
          service_name: new_resource.service_name
        )
        action :create
      end
    end

    # execute installation and remove files
    execute 'kubectl create -f dashboard' do
      cwd cache
      action :run
      notifies :delete, "directory[#{::File.join(cache, 'dashboard')}]"
    end
  end # end of dashboard installation
end
