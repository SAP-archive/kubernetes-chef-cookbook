# Taken from https://docs.chef.io/release_notes_ohai.html#ohai-6-vs-ohai-7-plugins
# This Ohai plugin is needed in the Vagrant environment, since the first interface
# used by node['ipaddress'] is the private interface and will always return the 
# same IP address. For Flannel and Docker this means that all pods have the same
# IP.

Ohai.plugin(:Vboxipaddress) do
  provides 'ipaddress'
  depends 'ipaddress', 'network/interfaces', 'virtualization/system', 'etc/passwd'
  collect_data(:default) do
    if virtualization['system'] == 'vbox'
      if !etc.nil? && !etc['passwd'].nil? && etc['passwd'].any? { |k,v| k == 'vagrant'}
        network_device = network['interfaces']['eth1'].nil? ? 'enp0s8' : 'eth1'
        if network['interfaces'][network_device]
          network['interfaces'][network_device]['addresses'].each do |ip, params|
            if params['family'] == ('inet')
              ipaddress ip
            end
          end
        end
      end
    end
  end
end