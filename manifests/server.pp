class osiris::server (
  $component_name                     = 'osiris-server',

  $install_path                       = '/var/osiris/server',
  $config_file                        = '/var/osiris/server/osiris-server.conf',
  $logging_config_file                = '/var/osiris/server/log4j2.xml',
  $properties_file                    = '/var/osiris/server/application.properties',

  $service_enable                     = true,
  $service_ensure                     = 'running',

  # osiris-server.properties config
  $application_port                   = undef,
  $grpc_port                          = undef,

  $serviceregistry_user               = undef,
  $serviceregistry_pass               = undef,
  $serviceregistry_host               = undef,
  $serviceregistry_port               = undef,
  $serviceregistry_url                = undef,

  $jdbc_url                           = undef,
  $jdbc_driver                        = 'org.postgresql.Driver',
  $jdbc_user                          = undef,
  $jdbc_password                      = undef,
  $jdbc_datasource_class_name         = 'org.postgresql.ds.PGSimpleDataSource',

  $api_base_path                      = '/secure/api/v2.0',
  $api_username_request_header        = undef,
  $api_email_request_header           = undef,
  $api_security_mode                  = 'NONE',

  $zoomanager_hostname                = undef,
  $zoomanager_grpc_port               = undef,

  $local_worker_hostname              = 'osiris-worker',
  $local_worker_grpc_port             = undef,

  # Pattern for building GUI URLs, based on the subsituted string '__PORT__'
  $gui_url_pattern                    = undef,

  $graylog_api_url                    = undef,
  $graylog_api_username               = undef,
  $graylog_api_password               = undef,

  $output_products_dir                = 'outputProducts',
  $refdata_dir                        = 'refData',

  $geoserver_enabled                  = true,
  $geoserver_url                      = undef,
  $geoserver_external_url             = undef,
  $geoserver_username                 = undef,
  $geoserver_password                 = undef,

  $resto_enabled                      = true,
  $resto_url                          = undef,
  $resto_external_products_collection = 'osirisInputs',
  $resto_external_products_model      = 'RestoModel_Osiris_Input',
  $resto_refdata_collection           = 'osirisRefData',
  $resto_refdata_model                = 'RestoModel_Osiris_Reference',
  $resto_output_products_collection   = 'osirisOutputs',
  $resto_output_products_model        = 'RestoModel_Osiris_Output',
  $resto_username                     = undef,
  $resto_password                     = undef,

  $broker_url                         = undef,
  $broker_username                    = undef,
  $broker_password                    = undef,

  $custom_config_properties           = {},
) {

  require ::osiris::globals

  contain ::osiris::common::datadir
  contain ::osiris::common::java
  # User and group are set up by the RPM if not included here
  contain ::osiris::common::user

  # This could potentially be on its own node, but it's easer to encapsulate it here
  contain ::osiris::serviceregistry

  $real_application_port = pick($application_port, $osiris::globals::server_application_port)
  $real_grpc_port = pick($grpc_port, $osiris::globals::server_grpc_port)

  $real_serviceregistry_user = pick($serviceregistry_user, $osiris::globals::serviceregistry_user)
  $real_serviceregistry_pass = pick($serviceregistry_pass, $osiris::globals::serviceregistry_pass)
  $real_serviceregistry_host = pick($serviceregistry_host, $osiris::globals::server_hostname)
  $real_serviceregistry_port = pick($serviceregistry_port, $osiris::globals::serviceregistry_application_port)
  $serviceregistry_creds = "${real_serviceregistry_user}:${real_serviceregistry_pass}"
  $serviceregistry_server = "${real_serviceregistry_host}:${real_serviceregistry_port}"
  $real_serviceregistry_url = pick($serviceregistry_url,
    "http://${serviceregistry_creds}@${serviceregistry_server}/eureka/")

  $default_jdbc_url =
    "jdbc:postgresql://${::osiris::globals::db_hostname}/${::osiris::globals::osiris_db_v2_name}?stringtype=unspecified"
  $real_db_url = pick($jdbc_url, $default_jdbc_url)
  $real_db_user = pick($jdbc_user, $::osiris::globals::osiris_db_username)
  $real_db_pass = pick($jdbc_password, $::osiris::globals::osiris_db_password)

  $real_api_username_request_header = pick($api_username_request_header, $osiris::globals::username_request_header)
  $real_api_email_request_header = pick($api_email_request_header, $osiris::globals::email_request_header)

  $real_geoserver_url = pick($geoserver_url, "${osiris::globals::base_url}${osiris::globals::context_path_geoserver}/")
  $real_geoserver_external_url = pick($geoserver_external_url,
    "${osiris::globals::base_url}${osiris::globals::context_path_geoserver}/")
  $real_geoserver_username = pick($geoserver_username, $osiris::globals::geoserver_osiris_username)
  $real_geoserver_password = pick($geoserver_username, $osiris::globals::geoserver_osiris_password)

  $real_resto_url = pick($resto_url, "${osiris::globals::base_url}${osiris::globals::context_path_resto}/")
  $real_resto_username = pick($resto_username, $osiris::globals::resto_osiris_username)
  $real_resto_password = pick($resto_username, $osiris::globals::resto_osiris_password)

  $real_broker_url = pick($broker_url, "${osiris::globals::base_url}${osiris::globals::context_path_broker}/")
  $real_broker_username = pick($broker_username, $osiris::globals::broker_osiris_username)
  $real_broker_password = pick($broker_password, $osiris::globals::broker_osiris_password)

  $real_graylog_api_url = pick($graylog_api_url, "${osiris::globals::base_url}${osiris::globals::graylog_api_path}")
  $real_graylog_api_username = pick($graylog_api_username, $osiris::globals::graylog_api_osiris_username)
  $real_graylog_api_password = pick($graylog_api_username, $osiris::globals::graylog_api_osiris_password)

  $real_gui_url_pattern = pick($gui_url_pattern, "${osiris::globals::base_url}/gui/:__PORT__/")

  ensure_packages(['osiris-server'], {
    ensure => 'latest',
    name   => 'osiris-server',
    tag    => 'osiris',
    notify => Service['osiris-server'],
  })

  file { ["${osiris::common::datadir::data_basedir}/${output_products_dir}", "${osiris::common::datadir::data_basedir}/${refdata_dir}"]:
    ensure  => directory,
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    mode    => '755',
    recurse => false,
    require => File[$osiris::common::datadir::data_basedir],
  }

  file { $config_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content =>
      'JAVA_OPTS="-DLog4jContextSelector=org.apache.logging.log4j.core.async.AsyncLoggerContextSelector -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager"'
    ,
    require => Package['osiris-server'],
    notify  => Service['osiris-server'],
  }

  ::osiris::logging::log4j2 { $logging_config_file:
    osiris_component => $component_name,
    require          => Package['osiris-server'],
    notify           => Service['osiris-server'],
  }

  file { $properties_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content => epp('osiris/server/application.properties.epp', {
      'logging_config_file'                => $logging_config_file,
      'server_port'                        => $real_application_port,
      'grpc_port'                          => $real_grpc_port,
      'serviceregistry_url'                => $real_serviceregistry_url,
      'jdbc_driver'                        => $jdbc_driver,
      'jdbc_url'                           => $real_db_url,
      'jdbc_user'                          => $real_db_user,
      'jdbc_password'                      => $real_db_pass,
      'jdbc_data_source_class_name'        => $jdbc_datasource_class_name,
      'api_base_path'                      => $api_base_path,
      'api_username_request_header'        => $real_api_username_request_header,
      'api_email_request_header'           => $real_api_email_request_header,
      'api_security_mode'                  => $api_security_mode,
      'graylog_api_url'                    => $real_graylog_api_url,
      'graylog_api_username'               => $real_graylog_api_username,
      'graylog_api_password'               => $real_graylog_api_password,
      'gui_url_pattern'                    => $real_gui_url_pattern,
      'output_products_dir'                => "${osiris::common::datadir::data_basedir}/${output_products_dir}",
      'refdata_dir'                        => "${osiris::common::datadir::data_basedir}/${refdata_dir}",
      'geoserver_enabled'                  => $geoserver_enabled,
      'geoserver_url'                      => $real_geoserver_url,
      'geoserver_external_url'             => $real_geoserver_external_url,
      'geoserver_username'                 => $real_geoserver_username,
      'geoserver_password'                 => $real_geoserver_password,
      'resto_enabled'                      => $resto_enabled,
      'resto_url'                          => $real_resto_url,
      'resto_external_products_collection' => $resto_external_products_collection,
      'resto_external_products_model'      => $resto_external_products_model,
      'resto_refdata_collection'           => $resto_refdata_collection,
      'resto_refdata_model'                => $resto_refdata_model,
      'resto_output_products_collection'   => $resto_output_products_collection,
      'resto_output_products_model'        => $resto_output_products_model,
      'resto_username'                     => $real_resto_username,
      'resto_password'                     => $real_resto_password,
      'broker_url'                         => $real_broker_url,
      'broker_username'                    => $real_broker_username,
      'broker_password'                    => $real_broker_password,
      'custom_properties'                  => $custom_config_properties,
    }),
    require => Package['osiris-server'],
    notify  => Service['osiris-server'],
  }

  $default_service_requires = [Package['osiris-server'], File[$properties_file]]
  $service_requires = defined(Class["::osiris::db"]) ? {
    true    => concat($default_service_requires, Class['::osiris::db']),
    default => $default_service_requires
  }

  service { 'osiris-server':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => $service_requires,
  }

}
