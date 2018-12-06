class osiris::webapp (
  $app_path          = '/var/www/html/osiris',
  $app_config_file   = 'scripts/osirisConfig.js',

  $osiris_url        = undef,
  $api_url           = undef,
  $api_v2_url        = undef,
  $osiris_portal_url = undef,
  $analyst_url       = undef,
  $sso_url           = 'https://eo-sso-idp.evo-pdgs.com',
  $mapbox_token      = 'pk.eyJ1IjoidmFuemV0dGVucCIsImEiOiJjaXZiZTM3Y2owMDdqMnVwa2E1N2VsNGJnIn0.A9BNRSTYajN0fFaVdJIpzQ',
) {

  require ::osiris::globals

  contain ::osiris::common::apache

  ensure_packages(['osiris-portal'], {
    ensure => 'latest',
    name   => 'osiris-portal',
    tag    => 'osiris',
  })

  $real_osiris_url = pick($osiris_url, $osiris::globals::base_url)
  $real_api_url = pick($api_url, "${osiris::globals::base_url}/secure/api/v1.0")
  $real_api_v2_url = pick($api_v2_url, "${$osiris::globals::base_url}/secure/api/v2.0")
  $real_portal_url = pick($osiris_portal_url, $osiris::globals::drupal_url)
  $real_analyst_url = pick($analyst_url, "${osiris::globals::base_url}/${osiris::globals::context_path_analyst}")

  file { "${app_path}/${app_config_file}":
    ensure  => 'present',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/webapp/osirisConfig.js.epp', {
      'osiris_url'        => $real_osiris_url,
      'api_url'           => $real_api_url,
      'api_v2_url'        => $real_api_v2_url,
      'sso_url'           => $sso_url,
      'osiris_portal_url' => $real_portal_url,
      'analyst_url'       => $real_analyst_url,
      'mapbox_token'      => $mapbox_token,
    }),
    require => Package['osiris-portal'],
  }

  ::apache::vhost { 'osiris-webapp':
    port       => '80',
    servername => 'osiris-webapp',
    docroot    => $app_path,
  }

}
