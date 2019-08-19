class osiris::broker (
  $activemq_version = '5.14.5'
) {

  require ::osiris::globals
  require ::osiris::common::java
  require ::epel

  $activemq_prereq = [ 'wget', 'unzip' ]
  package { $activemq_prereq: ensure => 'installed' } ->

  class { 'activemq':
    install              => 'source',
    version              => "${activemq_version}",
    install_source       => "http://archive.apache.org/dist/activemq/${activemq_version}/apache-activemq-${activemq_version}-bin.zip",
    install_dependencies => false,
    install_destination  => '/opt', # Default value
    create_user          => true, # Default value
    process_user         => 'activemq', # Default value
    disable              => true
  }

  file { "/opt/apache-activemq-${activemq_version}/bin/activemq":
    mode => '0755'
  } ->

  service { 'activemq_service':
    start  => "/opt/apache-activemq-${activemq_version}/bin/activemq start",
    stop   => "/opt/apache-activemq-${activemq_version}/bin/activemq stop",
    status => "/opt/apache-activemq-${activemq_version}/bin/activemq status",
    enable => true,
    ensure => 'running'
  }
}

