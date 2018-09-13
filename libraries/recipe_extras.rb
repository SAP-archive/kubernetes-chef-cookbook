
class Chef
  # Adding to the Chef::Recipe class
  class Recipe
    # kube['role'] returns the role of this instance
    # kube['minions'] returns an array of all the minions in a hash {'name' => 'ip'}
    # kube['masters'] contains the same as minions, but for the master(s)
    # kube['cluster'] contains all of the cluster information (masters and minions)
    def kube
      ret_val = {}
      cluster = node[cookbook_name]
      ret_val['masters'] = cluster['masters'].empty? ? project_masters : cluster['masters']
      ret_val['minions'] = cluster['minions'].empty? ? project_minions : cluster['minions']
      ret_val['cluster'] = (ret_val['masters'] + ret_val['minions']).group_by { |h| h[:name] }.map { |_k, v| v.reduce(:merge) }
      # NOTE: The ip_based_role is used in kitchen and vagrant environments
      ip_based_role = !cluster['masters'].select { |master| master['ip'] == node['ipaddress'] }.empty? ? 'master' : 'minion'
      ret_val['role'] = my_role.nil? ? ip_based_role : my_role
      ret_val
    end

    # private

    def my_role
      node_data = node.run_list.inspect
      cluster_id = node[cookbook_name]['cluster_id']
      return 'master' if node_data.include?("k8s_master_#{cluster_id}")
      return 'minion' if node_data.include?("k8s_minion_#{cluster_id}")
    end

    def project_masters
      cluster_id = node[cookbook_name]['cluster_id']
      kube_custom_search(:node, "role:k8s_master_#{cluster_id}")
    end

    def project_minions
      cluster_id = node[cookbook_name]['cluster_id']
      kube_custom_search(:node, "role:k8s_minion_#{cluster_id}")
    end

    # formats the returned data to be normalized
    def kube_custom_search(context, term)
      cluster_id = node[cookbook_name]['cluster_id']
      ret_val = []
      filter = { 'name' => ['fqdn'], 'ip' => ['ipaddress'] }
      # puts "search(#{context}, #{term}, filter_result: #{filter})"
      search(context, term, filter_result: filter).each do |inst|
        raw = "Raw search returns #{inst.inspect}"
        # >[{"name"=>"server-0", "ip"=>"ip-0"}, {"name"=>"server-1", "ip"=>"ip-1"}]
        raise raw + "\n" + err('no_master') if inst['name'].nil? && term == "role:k8s_master_#{cluster_id}"
        raise raw + "\n" + err('no_minion') if inst['name'].nil? && term == "role:k8s_minion_#{cluster_id}"
        ret_val.push(name: inst['name'].downcase, ip: inst['ip'])
      end
      if ret_val.empty?
        abort(err('no_master')) if term == "role:k8s_master_#{cluster_id}"
        abort(err('no_minion')) if term == "role:k8s_minion_#{cluster_id}"
      end
      ret_val # >[{"name"=>"server-0", "ip"=>"ip-0"}, {"name"=>"server-1", "ip"=>"ip-1"}]
    end

    def err(type)
      case type
      when 'no_role'
        'The role specified was incorrect or not supported!' + "\n" \
          'Please use the role "k8s_master_YOUR_CLUSTER_ID" or "k8s_minion_YOUR_CLUSTER_ID".  See the ' \
          'readme for more information.' \
          "\n The role(s) is(are): #{node['roles'].inspect}"
      when 'no_master'
        'You cannot create a cluster with no Master node.  At lease one of ' \
        'the nodes must include the role "k8s_master_YOUR_CLUSTER_ID". See the ' \
        'readme for more information.'
      when 'no_minion'
        'You cannot create a cluster with no Minion node(s).  At lease one of ' \
        'the nodes must include the role "k8s_minion_YOUR_CLUSTER_ID". See the ' \
        'readme for more information.'
      end
    end

    def find_first
      cluster_id = node[cookbook_name]['cluster_id']
      # returns the name and IP of the 1st master in a hash: {name: <server_name>, ip: <server_ip>}
      ret_val = {}
      kube_custom_search(:node, "role:k8s_master_#{cluster_id}").each do |server, ip|
        ret_val[:name] = server
        ret_val[:ip] = ip
        break # exits iteration after 1st pass
      end
      ret_val
    end

    def yum_updates_required?
      require 'mixlib/shellout'
      check_updates = Mixlib::ShellOut.new('yum check-update')
      check_updates.run_command
      check_updates.stdout[/((([0-9]+)\.)+)([0-9]+)/] # Returns nil (false) if there are no verison numbers in the stdout
    end
  end
end
