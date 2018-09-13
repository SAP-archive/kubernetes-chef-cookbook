name 'kubernetes_chef_cookbook' # ~FC067 Make sure that at least on suppors statement is present. This breaks TDC chef server currently though
maintainer 'Kaj-Sören Mossdorf'
maintainer_email 'kaj-soeren.mossdorf@sap.com'
source_url 'https://github.com/SAP/kubernetes-chef-cookbook' if respond_to?(:source_url)
license 'Apache 2.0'
description 'Installs/Configures kubernetes cluster'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '1.0.0'

chef_version '>12'

depends 'ohai'
