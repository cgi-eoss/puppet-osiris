class osiris::proxy::shibboleth (
  $service_ensure                   = 'running',
  $service_enable                   = true,

  $config_dir                       = '/etc/shibboleth',
  $metadata_subdir                  = 'metadata',

  $clock_skew                       = 180,

  $sp_id                            = 'https://fsdev.eoss-cloud.it/shibboleth',
  $home_url                         = 'https://fsdev.eoss-cloud.it/',
  $app_defaults_signing             = 'false',
  $app_defaults_encryption          = 'false',
  $app_defaults_remote_user         = 'Eosso-Person-commonName',
  $app_defaults_extra_attrs         = {},
  $session_lifetime                 = 7200,
  $session_timeout                  = 3600,
  $session_check_address            = false,
  $session_consistent_address       = false,
  $support_contact                  = 'info@eoss-cloud.it',
  $idp_id                           = 'https://eo-sso-idp.evo-pdgs.com:443/shibboleth',
  $idp_scope                        = 'evo-pdgs.com',
  $shib_xml_custom_tags             = '',
  $sp_assertion_consumer_services   = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Artifact',
      'location' => 'https://fsdev.eoss-cloud.it/Shibboleth.sso/SAML2/Artifact' },
  ],
  $sp_slo_service                   = {
    'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
    'location' => 'https://fsdev.eoss-cloud.it/Shibboleth.sso/SLO/Redirect'
  },
  $sp_name_id_formats               = ['urn:oasis:names:tc:SAML:2.0:nameid-format:transient'],
  $org_name                         = 'osiris',
  $org_display_name                 = 'Food Security TEP',
  $attribute_map                    = [
    { 'name' => 'urn:mace:dir:attribute-def:cn', 'id' => 'Eosso-Person-commonName' },
    { 'name' => 'urn:mace:dir:attribute-def:mail', 'id' => 'Eosso-Person-Email' }
  ],
  $idp_cert,
  $idp_artifact_resolution_services = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:1.0:bindings:SOAP-binding',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:8110/idp/profile/SAML1/SOAP/ArtifactResolution' },
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:8110/idp/profile/SAML2/SOAP/ArtifactResolution' },
  ],
  $idp_slo_service                  = {
    'binding'           => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
    'location'          => 'https://eo-sso-idp.evo-pdgs.com:443/idp/profile/SAML2/Redirect/SLO',
    'response_location' => 'https://eo-sso-idp.evo-pdgs.com:443/idp/profile/SAML2/Redirect/SLO'
  },
  $idp_sso_services                 = [
    { 'binding'  => 'urn:mace:shibboleth:1.0:profiles:AuthnRequest',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:443/idp/profile/Shibboleth/SSO' },
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:443/idp/profile/SAML2/Redirect/SSO' },
  ],
  $idp_name_id_formats              = [
    'urn:mace:shibboleth:1.0:nameIdentifier',
    'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
  ],
  $idp_attribute_services           = [
    { 'binding'  => 'urn:oasis:names:tc:SAML:1.0:bindings:SOAP-binding',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:8110/idp/profile/SAML1/SOAP/AttributeQuery' },
    { 'binding'  => 'urn:oasis:names:tc:SAML:2.0:bindings:SOAP',
      'location' => 'https://eo-sso-idp.evo-pdgs.com:8110/idp/profile/SAML2/SOAP/AttributeQuery' },
  ],
  $idp_keyname                      = "defcreds",
) {

  require ::epel
  require ::osiris::globals
  require ::osiris::repo::shibboleth

  ensure_packages(['shibboleth'], {
    ensure  => latest,
    require => Yumrepo['shibboleth'],
  })

  # mod_shib with the upstream shibboleth package must use a custom path
  class { ::apache::mod::shib:
    suppress_warning => true,
    mod_full_path    => $::operatingsystemmajrelease ? {
      '6'     => '/usr/lib64/shibboleth/mod_shib_22.so',
      '7'     => '/usr/lib64/shibboleth/mod_shib_24.so',
      default => fail("Unrecognised OS major release version ${::operatingsystemmajrelease}")
    },
    require          => Package['shibboleth'],
  }

  ensure_resource(service, 'shibd', {
    ensure     => $service_ensure,
    enable     => $service_enable,
    hasrestart => true,
    hasstatus  => true,
    require    => Package['shibboleth'],
  })

  file { "${config_dir}/shibboleth2.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/proxy/shibboleth/shibboleth2.xml.epp', {
      'clock_skew'                 => $clock_skew,
      'sp_id'                      => $sp_id,
      'home_url'                   => $home_url,
      'app_defaults_signing'       => $app_defaults_signing,
      'app_defaults_encryption'    => $app_defaults_encryption,
      'app_defaults_remote_user'   => $app_defaults_remote_user,
      'app_defaults_extra_attrs'   => $app_defaults_extra_attrs,
      'session_lifetime'           => $session_lifetime,
      'session_timeout'            => $session_timeout,
      'session_check_address'      => $session_check_address,
      'session_consistent_address' => $session_consistent_address,
      'support_contact'            => $support_contact,
      'idp_id'                     => $idp_id,
      'metadata_subdir'            => $metadata_subdir,
      'sp_key'                     => "${config_dir}/sp-key.pem",
      'sp_cert'                    => "${config_dir}/sp-cert.pem",
      'idp_keyname'                => $idp_keyname,
      'shib_xml_custom_tags'       => $shib_xml_custom_tags
    }),
    require => Package['shibboleth'],
    notify  => Service['shibd'],
  }

  file { "${config_dir}/attribute-policy.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/proxy/shibboleth/attribute-policy.xml.epp', {}),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/attribute-map.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/proxy/shibboleth/attribute-map.xml.epp', {
      'attributes' => $attribute_map,
    }),
    require => Package['shibboleth'],
  }

  file { "${config_dir}/${metadata_subdir}":
    ensure  => directory,
    mode    => '0755',
    owner   => 'root',
    group   => 'root',
    require => Package['shibboleth'],
  }

  file { "${config_dir}/${metadata_subdir}/sp-metadata.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/proxy/shibboleth/sp-metadata.xml.epp', {
      'sp_id'                       => $sp_id,
      'sp_cert'                     => $osiris::proxy::sp_cert,
      'assertion_consumer_services' => $sp_assertion_consumer_services,
      'slo_service'                 => $sp_slo_service,
      'name_id_formats'             => $sp_name_id_formats,
      'org_name'                    => $org_name,
      'org_display_name'            => $org_display_name,
      'org_url'                     => $home_url,
    }),
    require => File["${config_dir}/${metadata_subdir}"],
  }

  file { "${config_dir}/${metadata_subdir}/idp-metadata.xml":
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => epp('osiris/proxy/shibboleth/idp-metadata.xml.epp', {
      'idp_id'                       => $idp_id,
      'idp_scope'                    => $idp_scope,
      'idp_cert'                     => $idp_cert,
      'artifact_resolution_services' => $idp_artifact_resolution_services,
      'slo_service'                  => $idp_slo_service,
      'sso_services'                 => $idp_sso_services,
      'name_id_formats'              => $idp_name_id_formats,
      'attribute_services'           => $idp_attribute_services,
    }),
    require => File["${config_dir}/${metadata_subdir}"],
  }

}
