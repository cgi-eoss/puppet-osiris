class osiris::worker (
  $component_name           = 'osiris-worker',

  $install_path             = '/var/osiris/worker',
  $config_file              = '/var/osiris/worker/osiris-worker.conf',
  $logging_config_file      = '/var/osiris/worker/log4j2.xml',
  $properties_file          = '/var/osiris/worker/application.properties',
  $traefik_config_path      = '/var/osiris/traefik/',
  $traefik_config_file      = '/var/osiris/traefik/traefik.toml',
  $service_enable           = true,
  $service_ensure           = 'running',

  # osiris-worker application.properties config
  $application_port         = undef,
  $grpc_port                = undef,

  $serviceregistry_user     = undef,
  $serviceregistry_pass     = undef,
  $serviceregistry_host     = undef,
  $serviceregistry_port     = undef,
  $serviceregistry_url      = undef,

  $broker_url               = undef,
  $broker_username          = undef,
  $broker_password          = undef,

  $worker_environment       = 'LOCAL',

  $cache_concurrency        = 4,
  $cache_maxweight          = 1024,
  $cache_dir                = 'dl',
  $jobs_dir                 = 'jobs',

  $ipt_auth_endpoint        = 'https://finder.eocloud.eu/resto/api/authidentity',
  # These are not undef so they're not mandatory parameters, but must be set correctly if IPT downloads are required
  $ipt_auth_domain          = '__secret__',
  $ipt_download_base_url    = '__secret__',
  $traefik_admin_user       = 'admin:$apr1$5Rq.EMbw$2SXBjolJO1jw8WPNrsxSG1',
  $traefik_admin_port       = '8000',
  $traefik_service_port     = '10000',
  $custom_config_properties = {},
) {

  require ::osiris::globals

  contain ::osiris::common::datadir
  contain ::osiris::common::java
  # User and group are set up by the RPM if not included here
  contain ::osiris::common::user
  contain ::osiris::common::docker

  $real_application_port = pick($application_port, $osiris::globals::worker_application_port)
  $real_grpc_port = pick($grpc_port, $osiris::globals::worker_grpc_port)

  $real_serviceregistry_user = pick($serviceregistry_user, $osiris::globals::serviceregistry_user)
  $real_serviceregistry_pass = pick($serviceregistry_pass, $osiris::globals::serviceregistry_pass)
  $real_serviceregistry_host = pick($serviceregistry_host, $osiris::globals::server_hostname)
  $real_serviceregistry_port = pick($serviceregistry_port, $osiris::globals::serviceregistry_application_port)
  $serviceregistry_creds = "${real_serviceregistry_user}:${real_serviceregistry_pass}"
  $serviceregistry_server = "${real_serviceregistry_host}:${real_serviceregistry_port}"
  $real_serviceregistry_url = pick($serviceregistry_url, "http://${serviceregistry_creds}@${serviceregistry_server}/eureka/")

  $real_broker_url = pick($broker_url, "${osiris::globals::base_url}${osiris::globals::context_path_broker}/")
  $real_broker_username = pick($broker_username, $osiris::globals::broker_osiris_username)
  $real_broker_password = pick($broker_password, $osiris::globals::broker_osiris_password)

  ensure_packages(['osiris-worker'], {
    ensure => 'latest',
    name   => 'osiris-worker',
    tag    => 'osiris',
    notify => Service['osiris-worker'],
  })

  file { ["${osiris::common::datadir::data_basedir}/${cache_dir}", "${osiris::common::datadir::data_basedir}/${jobs_dir}"]:
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
    require => Package['osiris-worker'],
    notify  => Service['osiris-worker'],
  }

  ::osiris::logging::log4j2 { $logging_config_file:
    osiris_component => $component_name,
    require          => Package['osiris-worker'],
    notify           => Service['osiris-worker'],
  }

  file { $properties_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content => epp('osiris/worker/application.properties.epp', {
      'logging_config_file'   => $logging_config_file,
      'server_port'           => $real_application_port,
      'grpc_port'             => $real_grpc_port,
      'serviceregistry_url'   => $real_serviceregistry_url,
      'worker_environment'    => $worker_environment,
      'cache_basedir'         => "${osiris::common::datadir::data_basedir}/${cache_dir}",
      'cache_concurrency'     => $cache_concurrency,
      'cache_maxweight'       => $cache_maxweight,
      'jobs_basedir'          => "${osiris::common::datadir::data_basedir}/${jobs_dir}",
      'broker_url'            => $real_broker_url,
      'broker_username'       => $real_broker_username,
      'broker_password'       => $real_broker_password,
      'ipt_auth_endpoint'     => $ipt_auth_endpoint,
      'ipt_auth_domain'       => $ipt_auth_domain,
      'ipt_download_base_url' => $ipt_download_base_url,
      'custom_properties'     => $custom_config_properties,
    }),
    require => Package['osiris-worker'],
    notify  => Service['osiris-worker'],
  }

  service { 'osiris-worker':
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => [Package['osiris-worker'], File[$properties_file]],
  }

  file { $traefik_config_path:
    ensure => 'directory',
    owner  => $osiris::globals::user,
    group  => $osiris::globals::group,
  }

  file { $traefik_config_file:
    ensure  => 'present',
    owner   => $osiris::globals::user,
    group   => $osiris::globals::group,
    content => epp('osiris/traefik/traefik.toml.epp', {
      'traefik_admin_user'   => $traefik_admin_user,
      'traefik_admin_port'   => $traefik_admin_port,
      'traefik_service_port' => $traefik_service_port
    }),
    require => [File[$traefik_config_path]],
    notify  => Service['docker-traefik']
  }

  docker::run { 'traefik':
    image            => 'traefik:1.7.0',
    net              => 'host',
    extra_parameters => [ '--restart=always'],
    volumes          => ["$traefik_config_file:/etc/traefik/traefik.toml"],
    require          => [File[$traefik_config_file]]
  }
}
