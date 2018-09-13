def nodes
  cookbook_name = 'kubernetes_chef_cookbook'

  # Get all the attributes from the chef node
  node_run_attributes_tmp = JSON.parse(inspec.command('sudo bash -c "cat /tmp/kitchen/nodes/*"').stdout)
  # Only get the attributes relevant for our recipe (the first key in normal should be the cookbook-name)
  # This way the tests will still run if the cookbook gets renamed
  node_run_attributes_tmp1 = node_run_attributes_tmp['default']
  node_run_attributes = node_run_attributes_tmp['default']
  # Get all the attributes passed into kitchen
  node_user_attributes = json('/tmp/kitchen/dna.json').params
  # Merge the attributes so that the default values get overwritten with the kitchen ones
  cookbook_attributes = node_run_attributes_tmp1[cookbook_name].deep_merge(node_user_attributes[cookbook_name])
  mergable = {}
  mergable[cookbook_name] = cookbook_attributes
  node = node_run_attributes.deep_merge(mergable)
  # Get all the infos about the instance. Mainly interesting for node_system['ipaddress']
  node_system = node_run_attributes_tmp['automatic']
  { node: node, node_system: node_system }
end
