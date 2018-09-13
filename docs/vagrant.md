# Vagrant

## Installation

To install Vagrant follow the [Getting started](https://www.vagrantup.com/intro/index.html) guide. You'll find the installation files in the [download section](https://www.vagrantup.com/downloads.html) of the website.

## Required plugins

The Vagrant file also uses some plugins that need to be installed to provide the full functionalities. To install these, run the following command:

```
vagrant plugin install vagrant-berkshelf && vagrant plugin install vagrant-proxyconf && vagrant plugin install vagrant-aws && vagrant box add aws-dummy https://github.com/mitchellh/vagrant-aws/raw/master/dummy.box
```

## Configuration file

Rename the `config.sample.yml` file in `vagrant/` to config.yml and make the required adjustments. These options will be used to set up your vagrant instances.

|   Option  |     Type    | Description | Usage |  Default   |
| ------ | ----------- | ----------- | ----------- | ----------- |
|environment:||Environment specific settings||
|http_proxy:|String| HTTP proxy to be used with Vagrant ||
|https_proxy:|String| HTTPS proxy to be used with Vagrant ||
|no_proxy:|String| URLs for which not to apply the proxy ||
|general:||General settings that apply to all instances||
|chef_version:|Version String| Which chef version to use on the instances ||
|os:|String| OS on which Kubernetes will be installed (Ubuntu, rhel or centos) ||
|vpn: |String| If running behind a proxy use this flag to set the box's proxies to the ones configured in Vagrantfile. ||
|provider: |String| Which cloud provider to use (either local or aws). ||
|additional_host_entries: | String| Additional host entries to be placed in /etc/hosts ||
|local:|| Settings for the local provider ||
|ubuntu_box:|String|Ubuntu box to be used for vagrant||
|centos_box:|String|CentOS box to be used for vagrant||
|aws:||Settings to be used for the aws provider||
|key_pair_name:|String|Key pair name in AWS||
|key_pair_path:|String|Path to the local *.pem on your file system||
|security_groups:|Array of strings|Security groups to assign to the instances||
|subnet:|String|Subnet in which to deploy the instances||
|private_ip:|Boolean|Whether or not to assign a public IP to the instances||
|region:|String|In which region to deploy the instances||
|instance_type:|String|Which class of AWS EC2 instances to use||
|ubuntu_ami:|String|AMI-ID of the Ubuntu AMI to use||
|centos_ami:|String|AMI-ID of the CentOS AMI to use||
|kubernetes:||Kubernetes specific settings||
|version:|String|Which Kubernetes version to use (if `latest` is specified the latest version will be used)||
|installation_method:|String|From where to install the relevant packages (e.g. RHEL provides vendor packages for Kubernetes). Can be `source` (GitHub) or `vendor` ||
|virtual_api_server_ip:|String|IP address for the API server. This is intended to become a `keepalived` and `nginx` load balancing approach in later versions. For now it should be equal to the master server ip.||
|masters:|Integer|The number of masters to use. Currently only a single master setup is supported||
|master_ram:|Integer|Only relevant for vagrant: How much RAM to assign to the boxes||
|master_ips:|Hash of strings|Name and IP of the master server||
|minions:|Integer|Number of minions to be used in the Kubernetes cluster||
|minion_ram:|Integer|Only relevant for vagrant: How much RAM to assign to the boxes||
|minion_ips:|Hash of strings|Names and IPs of the minion boxes||
|ca_path:|String|Path to the ca.pem used for the Kubernetes certificate authority||
|ca_key_path:|String|Path to the ca-key.pem for the Kubernetes certificate authority||


## Starting vagrant
Locally: Set `general/provider` in config.yml to `local`

AWS: Set `general/provider` in config.yml to `aws`