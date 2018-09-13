# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
property :execute_install, [true, false], default: true

def cache
  Chef::Config[:file_cache_path]
end

load_current_value do |new_resource|
  # Check the service_name attribute
  require 'mixlib/shellout'
  cluster_status = Mixlib::ShellOut.new('kubectl cluster-info')
  cluster_status.run_command
  # monitoring is installed if stdout includes the service name
  install_status = false
  install_status = true if cluster_status.stdout['Heapster'] &&
                           (cluster_status.stdout['Grafana'] || cluster_status.stdout['monitoring-grafana']) &&
                           (cluster_status.stdout['InfluxDB'] || cluster_status.stdout['monitoring-influxdb'])
  puts "install_status = #{install_status}, recieved #{new_resource.execute_install}"
  execute_install install_status
end

action :configure do
  converge_if_changed :execute_install do
    # load files (with variables)
    directory ::File.join(cache, 'monitoring') do
      recursive true
      action :create
    end

    %w(influxdb heapster grafana).each do |depl|
      cookbook_file ::File.join(cache, 'monitoring', "#{depl}.yaml") do
        source "plugins/#{depl}.yaml"
        action :create
      end
    end

    # execute installation and remove files
    execute 'kubectl create -f monitoring' do
      cwd cache
      action :run
      notifies :delete, "directory[#{::File.join(cache, 'monitoring')}]"
    end
  end # end of monitoring installation
end
