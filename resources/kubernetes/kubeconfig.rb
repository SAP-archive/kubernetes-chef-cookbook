# Use custom resources in places where you find yourself repeating the same code
# in many different places or recipes.  It is not advisable to expect resources
# to return a value.  Instead, you might look at ohai plugins or libraries.

# If you would like to define a custom name for your resource, do so here.
# By default, your resource is named with the cookbook and the file name in the
# `/resources` directory, separated by an underscore
# resource_name :custom_name

# Use the properties to gather data from the resource declaration in the recipe
resource_name :kubectl

property :certificate_authority, String
property :client_certificate, String
property :client_key, String
property :cluster_name, String
property :context, String
property :file, String
property :user, String
property :virtual_api_server_ip, String

action_class do
  def run_command(command)
    kubeconfig = Mixlib::ShellOut.new(command)
    kubeconfig.run_command
    kubeconfig.stdout
  end
end

action :create do
  action_set_cluster
  action_set_credentials
  action_set_context
  action_use_context
end

action :set_cluster do
  stdout = run_command(
    <<-EOH
      kubectl config set-cluster #{new_resource.cluster_name} \
      --certificate-authority=#{new_resource.certificate_authority} \
      --embed-certs=true \
      --server=https://#{new_resource.virtual_api_server_ip}:6443 \
      --kubeconfig=#{new_resource.file}
    EOH
  )
  abort("Could not set cluster #{new_resource.cluster_name}") unless stdout.include?(new_resource.cluster_name)
end

action :set_credentials do
  stdout = run_command(
    <<-EOH
      kubectl config set-credentials #{new_resource.user} \
      --client-certificate=#{new_resource.client_certificate} \
      --client-key=#{new_resource.client_key} \
      --embed-certs=true \
      --kubeconfig=#{new_resource.file}
    EOH
  )
  abort("Could not set user #{new_resource.user}") unless stdout.include?(new_resource.user)
end

action :set_context do
  stdout = run_command(
    <<-EOH
      kubectl config set-context #{new_resource.context} \
      --cluster=#{new_resource.cluster_name} \
      --user=#{new_resource.user} \
      --kubeconfig=#{new_resource.file}
    EOH
  )
  abort("Could not set context #{new_resource.context}") unless stdout.include?(new_resource.context)
end

action :use_context do
  stdout = run_command("kubectl config use-context #{new_resource.context} --kubeconfig=#{new_resource.file}")
  abort("Could not use context #{new_resource.context}") unless stdout.include?(new_resource.context)
end
