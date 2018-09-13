# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
property :service_name, String, name_property: true
property :delay_execution, [true, false]

load_current_value do
  delay_execution ::File.exist?(service_register)
end

action :register_restart do
  # Make a list of pending services that need to be restarted.
  record_restart(new_resource.service_name)
end

action :restart_pending_services do
  converge_if_changed :delay_execution do # ~FC022 Resource condition within loop may not behave as expected?
    # Reload the daemon configurations if requested
    execute 'systemctl daemon-reload' do
      action :run
      only_if { needs_restart?('systemctl daemon-reload') }
    end

    # Go through the appropriate service list, and restart all that were requested
    role = node[cookbook_name]['kube_info']['role']
    node[cookbook_name]['kubernetes']["#{role}_services"].each do |svc|
      service svc do
        action :restart
        only_if { needs_restart?(svc) }
      end
    end

    # Delete the service restart registration file
    file service_register do
      action :delete
    end
  end
end

def service_register
  Dir.mkdir('/var/log/chef') unless Dir.exist?('/var/log/chef')
  # Location of the file to store the registration data
  '/var/log/chef/pending_services'
end

def needs_restart?(service_name)
  # If the name is present, restart is required, if the name is missing, returns
  # nil, which will evaluate to false
  ::File.read(service_register)[/^#{service_name}/]
end

def record_restart(service_name)
  # Ammends the file to include the service name on its own line
  ::File.open(service_register, 'a+') do |file|
    file.puts(service_name)
  end
end
