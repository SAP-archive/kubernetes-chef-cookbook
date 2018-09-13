# Kubernetes Chef Cookbook

## Description

This repository contains a sample cookbook (i.e. installation instructions) for managing Kubernetes masters and minions using the [Chef Automation platform](https://docs.chef.io/platform_overview.html). It utilizes the role assignments of each node on the chef server to bring
cluster awareness to each node. Furthermore multiple cluster in one Chef organization, based on the role names, are supported. On bare hardware (VM or physical) it will
provision the machines according to their role as defined on the server.

Currently, this cookbook is designed to run only once.

### About kubernetes
Kubernetes is an [open source](https://github.com/kubernetes/kubernetes) product
from Google's labs.  Its purpose is to ease the usage of containers.  It
does this by organizing them in to logical groups (pods), repairing them on
failure, and allowing them to interface with each other.  More than this, it
orchestrates all of this across a high-availability landscape.
To use this cookbook, you should be familiar with containers, high-availability
landscapes, and probably Docker and Kubernetes too.

## Requirements

Depending on your use-case either a working [Chef server](https://docs.chef.io/server_components.html) or [Vagrant setup](https://www.vagrantup.com/) is needed. See [docs](docs/) for installation instructions. To run this cookbook a chef client newer than version 12 is recommended.

### Supports
#### Operating Systems
- Ubuntu 16.04, 17.04
- RedHat Linux 7.4
- CentOS 7.4
#### Kubernetes versions
- Ubuntu
  - none via vendor (no packages available)
  - latest and before via source
- RedHat:
  - currently 1.5.2 via vendor (yum)
  - latest and before via source (Note: Currently docker will be installed from vendor, but the configuration will be changed)
- CentOS:
  - latest and before via source

## Download and installation
This cookbook can be run in various ways.
- For local development using Vagrant (see [Local development](#local-development))
- On a cloud service with pre-defined IPs (see [Vagrant file](vagrant/Vagrantfile) for examples)
- Using a Chef server (no Vagrant required, see [Chef setup](#chef-setup)). This has the added benefit of automatic node discovery, based on the roles of the nodes. Using chef-zero is not currently supported. The cookbook should remain in the node's runlist indefinitely, such that new nodes can be added on the fly. For more details see below.

## Configuration

### Local development
This cookbook can be developed locally by using Vagrant. It therefore includes a Vagrant file. This setup is only recommended for local development (there are currently heavy limitations in the cloud providers). For configuration instructions see [docs/vagrant.md](docs/vagrant.md).

### Chef setup
If you intend to run this cookbook using Chef, a basic setup is required. Please see [docs/chef.md](docs/chef.md) for further instructions.

## Limitations

This cookbook is currently only intended as sample code. It is therefore strongly recommended not to run this setup as is in production. Please also note that the code currently is not idempotent (should you measure such metrics).

## Known issues

There are currently no known issues.

## How to obtain support

Note: This project is as-is, no active support is provided.

## License and Authors
### License:

Copyright (c) 2018 SAP SE or an SAP affiliate company. All rights reserved.
This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the [LICENSE file](LICENSE.txt).

### Authors:
- [Dan-Joe Lopez](mailto:dan-joe.lopez@sap.com)
- [Kaj-Sören Mossdorf](mailto:kaj-soeren.mossdorf@sap.com)

