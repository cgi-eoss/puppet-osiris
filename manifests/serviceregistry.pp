class osiris::serviceregistry (
  $component_name           = 'osiris-serviceregistry',

  $install_path             = '/var/osiris/serviceregistry',
  $config_file              = '/var/osiris/serviceregistry/osiris-serviceregistry.conf',
  $logging_config_file      = '/var/osiris/serviceregistry/log4j2.xml',
  $properties_file          = '/var/osiris/serviceregistry/application.properties',

  $service_enable           = true,
  $service_ensure           = 'running',

  # osiris-serviceregistry application.properties config
  $application_port         = undef,
  $serviceregistry_user     = undef,
  $serviceregistry_pass     = undef,

  $custom_config_properties = {},
) {

  require ::osiris::globals

  contain ::osiris::common::java
  # User and group are set up by the RPM if not included here
  contain ::osiris::common::user

  $real_application_port = pick($application_port, $osiris::globals::serviceregistry_application_port)
  $real_serviceregistry_user = pick($serviceregistry_user, $osiris::globals::serviceregistry_user)
  $real_serviceregistry_pass = pick($serviceregistry_pass, $osiris::globals::serviceregistry_pass)

  # JDK is necessary to compile service stubs
  ensure_packages(['java-1.8.0-openjdk-devel'])

  ensure_packages(['osiris-serviceregistry'], {
    ensure => 'latest',
    name   => 'osiris-serviceregistry',
    tag    => 'osiris',
    notify => Service['osiris-serviceregistry'],
  })

  file { $config_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content => 'JAVA_HOME=/etc/alternatives/java_sdk
JAVA_OPTS="-DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"'
    ,
    require => Package['osiris-serviceregistry'],
    notify  => Service['osiris-serviceregistry'],
  }

  ::osiris::logging::log4j2 { $logging_config_file:
    osiris_component => $component_name,
    require          => Package['osiris-serviceregistry'],
    notify           => Service['osiris-serviceregistry'],
  }

  file { $properties_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content => epp('osiris/serviceregistry/application.properties.epp', {
      'logging_config_file'  => $logging_config_file,
      'server_port'          => $real_application_port,
      'serviceregistry_user' => $real_serviceregistry_user,
      'serviceregistry_pass' => $real_serviceregistry_pass,
      'custom_properties'    => $custom_config_properties,
    }),
    require => Package['osiris-serviceregistry'],
    notify  => Service['osiris-serviceregistry'],
  }

  service { 'osiris-serviceregistry':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [Package['osiris-serviceregistry'], File[$properties_file]],
  }

}
