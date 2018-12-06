# osiris

#### Table of Contents

1. [Description](#description)
1. [Setup - The basics of getting started with osiris](#setup)
    * [Setup requirements](#setup-requirements)
    * [Beginning with osiris](#beginning-with-osiris)
1. [Usage - Configuration options and additional functionality](#usage)
1. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
1. [Limitations - OS compatibility, etc.](#limitations)
1. [Development - Guide for contributing to the module](#development)

## Description

The osiris module lets you use Puppet to install and configure the Food Security TEP
service infrastructure.

[Osiris](https://github.com/cgi-eoss/osiris) is an open platform for the food security
community to access and exploit EO data. This Puppet module may be used to
set up the various components including the community hub, the Osiris webapp,
and the processing manager.

**Note:** Currently this module is only compatible with CentOS 6.

**<span style="color:red;">Warning:</span>** This module is incomplete.

## Setup

### Setup Requirements

* This module may manage a yum repository for package installation with the
  parameter `osiris::repo::location`. This may be the URL of a hosted repo, or
  an on-disk path to a static repo (e.g. built with `createrepo`) in the format
  `file:///path/to/osirisrepo/$releasever/local/$basearch`. The latter is useful
  for standalone `puppet apply` deployments.

## Usage

The osiris module may be used to install the Osiris components individually by the
classes:
* `osiris::db`
* `osiris::drupal`
* `osiris::geoserver`
* `osiris::monitor`
* `osiris::proxy`
* `osiris::resto`
* `osiris::server`
* `osiris::webapp`
* `osiris::worker`
* `osiris::wps`
* `osiris::broker`

Configuration parameters shared by these classes may be set via `osiris::globals`.

Interoperability between the components is managed via hostnames, which may be
resolved at runtime via DNS or manually, by overriding the `osiris::globals::hosts_override`
hash. See the `osiris::globals` class for available parameters, and the specific
component classes for how these are used, for example in `apache::vhost`
resources.

### Manual configuration actions

Some components of Osiris are not fully instantiated by this Puppet module.
Following the automated provisioning of an Osiris environment, some manual steps
must be carried out to ensure full functionality of some components. These may
be omitted when some functionality is not required.

The following list describes some of these possible post-installation actions:
* `osiris::drupal`: Drupal site initialisation &amp; content restoration
* `osiris::monitor`: Creation of graylog inputs &amp; dashboards
* `osiris::monitor`: Creation of grafana dashboards
* `osiris::worker`: Installation of downloader credentials
* `osiris::wps`: Restoration &amp; publishing of default Osiris services


## Limitations

This module currently only targets installation on CentOS 6 nodes.
