# Configure the gateway to the Osiris services, reverse-proxying to nodes implementing the other classes
class osiris::proxy (
  $vhost_name             = 'osiris-proxy',

  $enable_ssl             = false,
  $enable_sso             = false,
  $enable_letsencrypt     = false,
  $enable_basic_auth      = false,

  $basic_auth_user        = undef,
  $basic_auth_pwd         = undef,
  $user_file_path          = '/etc/httpd/passwords',

  $context_path_geoserver = undef,
  $context_path_resto     = undef,
  $context_path_webapp    = undef,
  $context_path_wps       = undef,
  $context_path_api_v2    = undef,
  $context_path_monitor   = undef,
  $context_path_logs      = undef,
  $context_path_eureka    = undef,
  $context_path_gui       = undef,
  $context_path_analyst   = undef,
  $context_path_broker    = undef,

  $tls_cert_path          = '/etc/pki/tls/certs/osiris_portal.crt',
  $tls_chain_path         = '/etc/pki/tls/certs/osiris_portal.chain.crt',
  $tls_key_path           = '/etc/pki/tls/private/osiris_portal.key',
  $tls_cert               = undef,
  $tls_chain              = undef,
  $tls_key                = undef,

  $sp_cert_path           = '/etc/shibboleth/sp-cert.pem',
  $sp_key_path            = '/etc/shibboleth/sp-key.pem',
  $sp_cert                = undef,
  $sp_key                 = undef,
) {

  require ::osiris::globals

  contain ::osiris::common::apache

  ensure_packages(['apr-util-pgsql'])
  include ::apache::mod::headers
  include ::apache::mod::proxy
  include ::apache::mod::rewrite

  $default_proxy_config = {
    docroot    => '/var/www/html',
    vhost_name => '_default_', # The default landing site should always be Drupal
    proxy_dest => 'http://osiris-drupal', # Drupal is always mounted at the base_url
    rewrites   => [
      {
        rewrite_rule => ['^/app$ /app/ [R]']
      },
      {
        # default rewrite requested by ESA scan
        rewrite_cond => ['%{REQUEST_METHOD} ^(TRACE|TRACK)'],
        rewrite_rule => ['.* - [F]']
      }
    ],
    options    => [ '-Indexes' ]
  }

  $real_context_path_geoserver = pick($context_path_geoserver, $osiris::globals::context_path_geoserver)
  $real_context_path_resto = pick($context_path_resto, $osiris::globals::context_path_resto)
  $real_context_path_webapp = pick($context_path_webapp, $osiris::globals::context_path_webapp)
  $real_context_path_wps = pick($context_path_wps, $osiris::globals::context_path_wps)
  $real_context_path_api_v2 = pick($context_path_api_v2, $osiris::globals::context_path_api_v2)
  $real_context_path_monitor = pick($context_path_monitor, $osiris::globals::context_path_monitor)
  $real_context_path_logs = pick($context_path_logs, $osiris::globals::context_path_logs)
  $real_context_path_eureka = pick($context_path_eureka, $osiris::globals::context_path_eureka)
  $real_context_path_analyst = pick($context_path_analyst, $osiris::globals::context_path_analyst)
  $real_context_path_broker = pick($context_path_broker, $osiris::globals::context_path_broker)

  # Directory/Location directives - cannot be an empty array...
  $default_directories = [
    {
      'provider'        => 'location',
      'path'            => $real_context_path_logs,
      'custom_fragment' =>
      "RequestHeader set X-Graylog-Server-URL \"${osiris::globals::base_url}${osiris::globals::graylog_api_path}\""
    }
  ]

  # Reverse proxied paths
  $default_proxy_pass = [
    {
      'path'   => $real_context_path_geoserver,
      'url'    =>
      "http://${osiris::globals::geoserver_hostname}:${osiris::globals::geoserver_port}${real_context_path_geoserver}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_resto,
      'url'    => "http://${osiris::globals::resto_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_webapp,
      'url'    => "http://${osiris::globals::webapp_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_wps,
      'url'    => "http://${osiris::globals::wps_hostname}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_api_v2,
      'url'    =>
      "http://${osiris::globals::server_hostname}:${osiris::globals::server_application_port}${real_context_path_api_v2}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_monitor,
      'url'    => "http://${osiris::globals::monitor_hostname}:${osiris::globals::grafana_port}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_logs,
      'url'    => "http://${osiris::globals::monitor_hostname}:${osiris::globals::graylog_port}${osiris::globals::graylog_context_path}",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_eureka,
      'url'    => "http://${osiris::globals::server_hostname}:${osiris::globals::serviceregistry_application_port}/eureka",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_analyst,
      'url'    => "http://${osiris::globals::ui_hostname}/analyst",
      'params' => { 'retry' => '0' }
    },
    {
      'path'   => $real_context_path_broker,
      'url'    => "http://${osiris::globals::broker_hostname}",
      'params' => { 'retry' => '0' }
    }
  ]

  $default_proxy_pass_match = [
    {
      'path'   => '^/gui/(.*)$',
      'url'    => "http://${osiris::globals::default_gui_hostname}\$1",
      'params' => { 'retry' => '0' }
    }
  ]

  if $enable_sso {
    unless ($tls_cert and $tls_key) {
      fail("osiris::proxy requires \$tls_cert and \$tls_key to be set if \$enable_sso is true")
    }
    contain ::osiris::proxy::shibboleth

    # add the SSO certificate (which may be different than the portal one)
    file { $sp_cert_path:
      ensure  => present,
      mode    => '0644',
      owner   => 'shibd',
      group   => 'shibd',
      content => $sp_cert,
    }

    file { $sp_key_path:
      ensure  => present,
      mode    => '0400',
      owner   => 'shibd',
      group   => 'shibd',
      content => $sp_key,
    }

    # Add the /Shibboleth.sso SP callback location, enable the minimal support for the root, and add secured paths
    $directories = concat([
      {
        'provider'   => 'location',
        'path'       => '/Shibboleth.sso',
        'sethandler' => 'shib'
      },
      {
        'provider' => 'location',
        'path'     => '/config'
      },
      {
        'provider'              => 'location',
        'path'                  => '/',
        'auth_type'             => 'shibboleth',
        'shib_use_headers'      => 'On',
        'shib_request_settings' => { 'requireSession' => '0' },
        'custom_fragment'       => $::operatingsystemmajrelease ? {
          '6'     => 'ShibCompatWith24 On',
          default => ''
        },
        'auth_require'          => 'shibboleth',
      },
      {
        'provider'              => 'location',
        'path'                  => $real_context_path_webapp,
        'auth_type'             => 'shibboleth',
        'shib_use_headers'      => 'On',
        'shib_request_settings' => { 'requireSession' => '1' },
        'custom_fragment'       => $::operatingsystemmajrelease ? {
          '6'     => 'ShibCompatWith24 On',
          default => ''
        },
        'auth_require'          => 'valid-user',
      },
      {
        'provider'        => 'location',
        'path'            => '/secure',
        'custom_fragment' =>
        "<If \"-n req('Authorization')\">
    AuthType Basic
    AuthName 'Osiris API access'
    AuthBasicProvider dbd
    AuthDBDUserPWQuery \"${osiris::globals::proxy_dbd_query}\"
    Require valid-user
    RewriteEngine On
    RewriteCond %{REMOTE_USER} ^(.*)$
    RewriteRule ^(.*)$ - [E=R_U:%1]
    RequestHeader set Eosso-Person-commonName %{R_U}e
</If>
<Else>
    Require valid-user
    AuthType shibboleth
    ShibRequestSetting requireSession 1
    ShibUseHeaders On
</Else>
"
      }
    ], $default_directories)

    # Insert the callback location at the start of the reverse proxy list
    $proxy_pass = concat([{
      'path'         => '/Shibboleth.sso',
      'url'          => '!',
      'reverse_urls' => [],
      'params'       => { 'retry' => '0' }
    }], $default_proxy_pass)
    $proxy_pass_match = $default_proxy_pass_match
  } elsif $enable_basic_auth {
    unless ($basic_auth_user and $basic_auth_pwd) {
      fail("osiris::proxy requires \$basic_auth_user and \$basic_auth_pwd to be set when \$enable_basic_auth is true")
    }

    $basic_auth_hashed_pwd = apache::apache_pw_hash($basic_auth_pwd)
    file { $user_file_path:
      ensure  => present,
      mode    => '0600',
      owner   => 'root',
      group   => 'root',
      content => "$basic_auth_user:$basic_auth_hashed_pwd"
    }

    $directories = concat([
      {
        provider       => 'location',
        path           => '/',
        auth_type      => 'Basic',
        auth_name      => 'Basic Auth',
        auth_user_file => $user_file_path,
        auth_require   => 'valid-user',
      }, $default_directories
    ])
    $proxy_pass = $default_proxy_pass
    $proxy_pass_match = $default_proxy_pass_match
  } else {
    $directories = $default_directories
    $proxy_pass = $default_proxy_pass
    $proxy_pass_match = $default_proxy_pass_match
  }


  if $enable_ssl {
    unless ($enable_letsencrypt or ($tls_cert and $tls_key)) {
      fail("osiris::proxy requres \$tls_cert and \$tls_key to be set if \$enable_ssl is true and \$enable_letsencrypt is false")
    }

    if $enable_letsencrypt {
      contain ::osiris::proxy::letsencrypt
    }

    if $tls_cert {
      file { $tls_cert_path:
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => $tls_cert,
      }
      $real_tls_cert_path = $tls_cert_path
    } elsif $enable_letsencrypt {
      $real_tls_cert_path = "/etc/letsencrypt/live/$vhost_name/cert.pem"
    }

    if $tls_chain {
      file { $tls_chain_path:
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        content => $tls_chain,
      }
      $real_tls_chain_path = $tls_chain_path
    } elsif $enable_letsencrypt {
      $real_tls_chain_path = "/etc/letsencrypt/live/$vhost_name/chain.pem"
    } else {
      $real_tls_chain_path = undef
    }

    if $tls_key {
      file { $tls_key_path:
        ensure  => present,
        mode    => '0600',
        owner   => 'root',
        group   => 'root',
        content => $tls_key,
      }
      $real_tls_key_path = $tls_key_path
    } elsif $enable_letsencrypt {
      $real_tls_key_path = "/etc/letsencrypt/live/$vhost_name/privkey.pem"
    }

    unless $enable_letsencrypt {
      apache::vhost { "redirect ${vhost_name} non-ssl":
        servername      => $vhost_name,
        port            => '80',
        docroot         => '/var/www/redirect',
        redirect_status => 'permanent',
        redirect_dest   => "https://${vhost_name}/"
      }
    }
    apache::vhost { $vhost_name:
      servername             => $vhost_name,
      port                   => '443',
      ssl                    => true,
      ssl_cert               => $real_tls_cert_path,
      ssl_chain              => $real_tls_chain_path,
      ssl_key                => $real_tls_key_path,
      default_vhost          => true,
      shib_compat_valid_user => 'On',
      request_headers        => [
        'set X-Forwarded-Proto "https"'
      ],
      directories            => $directories,
      proxy_pass             => $proxy_pass,
      proxy_pass_match       => $proxy_pass_match,
      *                      => $default_proxy_config,
    }
  } else {
    apache::vhost { $vhost_name:
      port             => '80',
      default_vhost    => true,
      directories      => $directories,
      proxy_pass       => $proxy_pass,
      proxy_pass_match => $proxy_pass_match,
      *                => $default_proxy_config
    }
  }

  # authn_dbd does not install properly, used for Puppetised API key access
  # TODO: Remove functionality or solve install problem
  #
  # class { 'apache::mod::authn_dbd':
  #   authn_dbd_params   => "host=${osiris::globals::proxy_dbd_db} port=${osiris::globals::proxy_dbd_port} user=${osiris::globals::osiris_db_v2_api_keys_reader_username} password=${osiris::globals::osiris_db_v2_api_keys_reader_password} dbname=${osiris::globals::osiris_db_v2_name}",
  #   authn_dbd_dbdriver => "${osiris::globals::proxy_dbd_dbdriver}"
  # }


}
