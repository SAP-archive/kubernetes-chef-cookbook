# Chef

## Installation

To install the chef client download the [ChefDK](https://downloads.chef.io/chefdk). Follow these instructions to set up a [Chef server](https://docs.chef.io/install_server.html). Please read these detailed instructions of [runlists and roles](https://docs.chef.io/run_lists.html) if you are unfamiliar with these concepts (since these are vital for the use of this method).

## Getting started

NOTE: Currently this cookbook is not yet idempotent.

- Add this cookbook and its dependencies to your chef server.
- Create 2 identical roles on the server, with the runlist `recipe[kubernetes_chef_cookbook]`
  - `role[k8s_master_YOUR_CLUSTER_ID]`, sample JSON config:
  ```
    {
      "name": "k8s_master_YOUR_CLUSTER_ID",
      "default_attributes": {
        "kubernetes_chef_cookbook": {
          "cluster_id": "YOUR_CLUSTER_ID",
          "root_ca": {
            "ca": "/path/to/ca.pem",
            "ca_key": "/path/to/ca-key.pem"
          }
        }
      },
      "chef_type": "role",
      "json_class": "Chef::Role",
      "description": "The role to identify the server as a master in the cluster YOUR_CLUSTER_ID.",
      "run_list": [
        "recipe[kubernetes_chef_cookbook]"
      ]
    }
  ```
  - `role[k8s_minion_YOUR_CLUSTER_ID]`
  ```
    {
      "name": "k8s_minion_YOUR_CLUSTER_ID",
      "default_attributes": {
        "kubernetes_chef_cookbook": {
          "cluster_id": "YOUR_CLUSTER_ID",
          "root_ca": {
            "ca": "/path/to/ca.pem",
            "ca_key": "/path/to/ca-key.pem"
          }
        }
      },
      "chef_type": "role",
      "json_class": "Chef::Role",
      "description": "The role to identify the server as a minion.",
      "run_list": [
        "recipe[kubernetes_chef_cookbook]"
      ]
    }
  ```
  - optionally, add any attributes that you need (below) to the roles.
- Add the `role[k8s_master_YOUR_CLUSTER_ID]` to the runlist of one node. (see kubernetes_chef_cookbook/roles)
- Add the `role[k8s_minion_YOUR_CLUSTER_ID]` to the runlist of the node(s) that you want to be in the cluster.
- Run `chef-client` on all the nodes concurrently - starting with the master.
- Check the console output or the Chef server log for details of the deployment.

NOTE: The definition of ```YOUR_CLUSTER_ID``` is important, so that you will be able to run multiple clusters in the same chef organization! To configure a second cluster, simply adjust the attributes of the other's cluster machines to a different `CLUSTER_ID`.

## Adding new nodes

Bootstrap the node to the chef server, add the minion role for the desired cluster to the runlist, and run chef-client.

## Roles vs. Tags
The decision to utilize roles over tags is simply to satisfy the limitations of
terraform's chef provisioner.  It is not able to add chef server tags, so to
enable a cluster to be setup with a single script, roles are used instead.

The cookbook relies on roles to identify the node's own execution order and for
it to be cluster aware.

## Attributes
The following attributes are available to customize the cluster:

|   Key  |     Type    | Description |   Default   |
| ------ | ----------- | ----------- | ----------- |
|`['kubernetes_chef_cookbook']['cluster_id']` | String | This is required! It has to match the `YOUR_CLUSTER_ID` part of the nodes role (for a given cluster)! | `role[k8s_minion_YOUR_CLUSTER_ID] => YOUR_CLUSTER_ID`
|`['kubernetes_chef_cookbook']['installation_method']` | String | Whether Kubernetes should be installed from the vendor or the Google source (using pre-made packages, no compilation). Can be 'vendor' or 'source' | `'source'`
| `['kubernetes_chef_cookbook']['proxy']`           | String | The proxy server to set on all the nodes. | `''` |
|`['kubernetes_chef_cookbook']['common_packages']` | Array | An array of common packages that should be installed. | `%w(keepalived nginx)` |
|`['kubernetes_chef_cookbook']['additional_host_entries']` | String | A String of additional host entries added to /etc/hots | `''` |
|`['kubernetes_chef_cookbook']['kubernetes']['version']` | String | The version of Kubernetes that will be installed. Note: If the `installation_method` is vendor and the vendor does not provide the configured Kubernetes version, the vendor's version will be used and Kubernetes configured for that specific version. | `'v1.9.0'`
|`['kubernetes_chef_cookbook']['kubernetes']['repository']` | String | The URL of the Kubernetes repository, incorporates the version attribute by default. So if you want to change the version, just adapt the version attribute. |  `"http://storage.googleapis.com/kubernetes-release/release/#{node['kubernetes_chef_cookbook']['kubernetes']['version']}/bin/linux/amd64"`
|`['kubernetes_chef_cookbook']['kubernetes']['master_services']` | Array | An array of services that will be configured on the master | `%w(kube-apiserver kube-controller-manager kube-scheduler)`
|`['kubernetes_chef_cookbook']['kubernetes']['minion_services']` | Array | An array of services that will be configured on the minion | `%w(kubelet kube-proxy)`
|`['kubernetes_chef_cookbook']['kubernetes']['master_packages']` | Array | An array of kubernetes packages that will be installed on the master (being appended to the repository-url) if installation_method == 'source'. | `%w(kube-apiserver kube-controller-manager kubectl kube-scheduler)`
|`['kubernetes_chef_cookbook']['kubernetes']['minion_packages']` | Array | An array of kubernetes packages that will be installed on the minion (being appended to the repository-url) if installation_method == 'source'. | `%w(kubectl kubelet kube-proxy)`
|`['kubernetes_chef_cookbook']['kubernetes']['cni']` | String | Which container network to use. Currently only flannel is supported. | `'flannel'`
|`['kubernetes_chef_cookbook']['kubernetes']['virtual_api_server_ip']` | String | The virtual ip of the api server under which the master(-cluster), meaning keepalived will be reachable. If running in Vagrant, just use the ip of the master instance. | `''`
| `['kubernetes_chef_cookbook']['kubernetes']['kube_ip_range']`   | String | Choose any IP range make sure it does not overlap with any other IP range |  `'10.254.0.0/16'` |
| `['kubernetes_chef_cookbook']['kubernetes']['kube_service_ip']` | String | First IP from service cluster IP range is always allocated to Kubernetes Service | `'10.254.0.1'` |
| `['kubernetes_chef_cookbook']['kubernetes']['subnet']`    | String | The subnet your infrastructure will ive on. | `'10.58.122.0/23'` |
| `['kubernetes_chef_cookbook']['kubernetes']['cgroup_driver']`    | String | The cgroup_driver both the kubelet and docker will use. | `'cgroupfs'` |
|`['kubernetes_chef_cookbook']['masters']` | A hash containing the master nodes in the cluster. If not set, this will be built automatically. | `{}` # { master1: '192.168.0.201', master2: '192.169.0.202', ... }
|`['kubernetes_chef_cookbook']['minions']` | A hash containing the minion nodes in the cluster. If not set, this will be built automatically. | `{}` # { minion1: '192.168.0.201', minion2: '192.169.0.202', ... }
|`['kubernetes_chef_cookbook']['plugins']` | Array | An array of plugins that will get installed into the cluster. Currently supported: kube-dns, dashboard, monitoring(InfluxDB, Grafana, Heapster). | `['kube-dns', 'dashboard']`
|`['kubernetes_chef_cookbook']['root_ca']['ca']` | String | URL to the root certificate. Will be fetched using remote_file | `''`
|`['kubernetes_chef_cookbook']['root_ca']['ca_key']` | String | URL to the root certificate's key. Will be fetched using remote_file | `''`
|`['kubernetes_chef_cookbook']['docker']['vendor_version'][platform]` | String | Which docker version to install on 'platform'. | `'17.12.0~ce-0~ubuntu' for ubuntu`
|`['kubernetes_chef_cookbook']['docker']['package_name'][platform]` | String | How the package is called in the package manager of the corresponding platform. | `'docker-ce' for ubuntu`
| `['kubernetes_chef_cookbook']['docker]['subnet']`   | String | Depends on Docker version | `'172.17.0.0/24'` |
|`['kubernetes_chef_cookbook']['flannel']['source_version']` | String | flannel source version to use |  `'v0.10.0'`
|`['kubernetes_chef_cookbook']['flannel']['vendor_version']` | String | flannel vendor version to use, platform = 'redhat', 'centos', ... |  `'0.5.5-2.el7' for 'redhat','centos'`
|`['kubernetes_chef_cookbook']['flannel']['repository']` | String | flannel repository to use, incorporates the version attribute by default. | `"http://github.com/coreos/flannel/releases/download/#{node['kubernetes_chef_cookbook']['flannel']['source_version']}/flannel-#{node['kubernetes_chef_cookbook']['flannel']['source_version']}-linux-amd64.tar.gz"`
|`['kubernetes_chef_cookbook']['flannel']['etcd_prefix']` | String | Which prefix to use when storing flannel related keys in etcd | `'/kube/network'`
| `['kubernetes_chef_cookbook']['flannel']['standard_interface']`  | String | The instance's network interface used by flannel. NOTE: This will be automatically set in Vagrant and should be left alone. | `nil` |
| `['kubernetes_chef_cookbook']['flannel']['subnet']`  | String | Choose any IP range just make sure it does not overlap with any other IP range | `'172.17.0.0/16'` |
|`['kubernetes_chef_cookbook']['etcd']['source_version']` | String | etcd source version to use | `'v3.3.0'`
|`['kubernetes_chef_cookbook']['etcd']['vendor_version'][platform]` | String | etcd vendor version to use, platform = 'redhat', 'centos', ... | `'3.2.11-1.el7' for 'redhat','centos`
|`['kubernetes_chef_cookbook']['etcd']['repository']` | String | etcd repository to use, incorporates the version attribute by default. |  `"http://github.com/coreos/etcd/releases/download/#{node['kubernetes_chef_cookbook']['etcd']['source_version']}/etcd-#{node['kubernetes_chef_cookbook']['etcd']['source_version']}-linux-amd64.tar.gz"`
|`['kubernetes_chef_cookbook']['etcd']['cluster_ips']` | Array | The hostnames and ips of the etcd instances. If no instances are specified, etcd will be installed on the master instances. | `[]` # [{ name: '', ip: ''}, { name: '', ip: '' }]
| `['kubernetes_chef_cookbook']['kube-dns']['cluster_ip']`    | String | The IP address the cluster's kube-dns service will use. | `'10.254.0.2'` |
| `['kubernetes_chef_cookbook']['kube-dns']['cluster_domain']` | String | The domain of the cluster used in kube-dns. | `'cluster.local'` |
| `['kubernetes_chef_cookbook']['helm']['version']`    | String | Which helm version to use. | `'v2.8.1'` |
| `['kubernetes_chef_cookbook']['helm']['repository']` | String | From where to download helm, incorporates the version attribute by default. | `'"https://storage.googleapis.com/kubernetes-helm/helm-#{node['kubernetes_chef_cookbook']['helm']['version']}-linux-amd64.tar.gz"'` |
