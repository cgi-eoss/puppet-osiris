class osiris::db::postgresql (
  $db_name                        = $osiris::globals::osiris_db_name,
  $db_v2_name                     = $osiris::globals::osiris_db_v2_name,
  $db_username                    = $osiris::globals::osiris_db_username,
  $db_password                    = $osiris::globals::osiris_db_password,

  $db_resto_name                  = $osiris::globals::osiris_db_resto_name,
  $db_resto_username              = $osiris::globals::osiris_db_resto_username,
  $db_resto_password              = $osiris::globals::osiris_db_resto_password,
  $db_resto_su_username           = $osiris::globals::osiris_db_resto_su_username,
  $db_resto_su_password           = $osiris::globals::osiris_db_resto_su_password,

  $db_zoo_name                    = $osiris::globals::osiris_db_zoo_name,
  $db_zoo_username                = $osiris::globals::osiris_db_zoo_username,
  $db_zoo_password                = $osiris::globals::osiris_db_zoo_password,

  $db_v2_api_keys_table           = $osiris::globals::osiris_db_v2_api_keys_table,
  $db_v2_api_users_table          = $osiris::globals::osiris_db_v2_api_users_table,
  $db_v2_api_keys_reader_username = $osiris::globals::osiris_db_v2_api_keys_reader_username,
  $db_v2_api_keys_reader_password = $osiris::globals::osiris_db_v2_api_keys_reader_password,
) {

  # EPEL is required for the postgis extensions
  require ::epel
  Yumrepo['epel'] -> Package<|tag == 'postgresql'|>

  if $osiris::db::trust_local_network {
    $acls = [
      "host ${db_name} ${db_username} samenet md5",
      "host ${db_v2_name} ${db_username} samenet md5",
      "host ${db_resto_name} ${db_resto_username} samenet md5",
      "host ${db_resto_name} ${db_resto_su_username} samenet md5",
      "host ${db_zoo_name} ${db_zoo_username} samenet md5",
    ]
  } else {
    $acls = [
      "host ${db_name} ${db_username} ${osiris::globals::wps_hostname} md5",
      "host ${db_name} ${db_username} ${osiris::globals::drupal_hostname} md5",
      "host ${db_name} ${db_username} ${osiris::globals::server_hostname} md5",
      # Access to v2 db only required for osiris-server
      "host ${db_v2_name} ${db_username} ${osiris::globals::server_hostname} md5",
      # Access to resto db only required for osiris-resto
      "host ${db_resto_name} ${db_resto_username} ${osiris::globals::resto_hostname} md5",
      "host ${db_resto_name} ${db_resto_su_username} ${osiris::globals::resto_hostname} md5",
      # Access to zoo db only required for osiris-wps
      "host ${db_zoo_name} ${db_zoo_username} ${osiris::globals::wps_hostname} md5",
      "host ${db_v2_name} ${db_v2_api_keys_reader_username} ${osiris::globals::drupal_hostname} md5"
    ]
  }

  # We have to control the package version
  class { ::postgresql::globals:
    manage_package_repo => true,
    version             => '9.5',
  } ->
  class { ::postgresql::server:
    ipv4acls         => $acls,
    listen_addresses => '*',
  }
  class { ::postgresql::server::postgis: }
  class { ::postgresql::server::contrib: }

  ::postgresql::server::db { 'osirisdb':
    dbname   => $db_name,
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
    grant    => 'ALL',
  }
  ::postgresql::server::db { 'osirisdb_v2':
    dbname   => $db_v2_name,
    user     => $db_username,
    password => postgresql_password($db_username, $db_password),
    grant    => 'ALL',
  }
  ::postgresql::server::db { 'osirisdb_resto':
    dbname   => $db_resto_name,
    user     => $db_resto_username,
    password => postgresql_password($db_resto_username, $db_resto_password),
    grant    => 'ALL',
  }
  ::postgresql::server::role { 'osirisdb_resto_admin':
    username      => $db_resto_su_username,
    password_hash => postgresql_password($db_resto_su_username, $db_resto_su_password),
    db            => $db_resto_name,
    createdb      => false,
    superuser     => true,
    require       => Postgresql::Server::Db['osirisdb_resto'],
  }
  ::postgresql::server::db { 'osirisdb_zoo':
    dbname   => $db_zoo_name,
    user     => $db_zoo_username,
    password => postgresql_password($db_zoo_username, $db_zoo_password),
    grant    => 'ALL',
  }

  # Associated with puppetised key access (see proxy.pp)
  # TODO: Remove functionality or solve authn_dbd install problem
  #
  # ::postgresql::server::role { 'osirisdb_apikeys':
  #   username      => $db_v2_api_keys_reader_username,
  #   password_hash => postgresql_password($db_v2_api_keys_reader_username, $db_v2_api_keys_reader_password),
  #   require       => Postgresql::Server::Db['osirisdb_v2']
  # }
  #
  # ::postgresql::server::table_grant { 'API Key read permission':
  #   db        => $db_v2_name,
  #   table     => $db_v2_api_keys_table,
  #   privilege => 'SELECT',
  #   role      => "${db_v2_api_keys_reader_username}",
  #   require   => Postgresql::Server::Role['osirisdb_apikeys']
  # }
  #
  # ::postgresql::server::table_grant { 'Users read permission':
  #   db        => $db_v2_name,
  #   table     => $db_v2_api_users_table,
  #   privilege => 'SELECT',
  #   role      => "${db_v2_api_keys_reader_username}",
  #   require   => Postgresql::Server::Role['osirisdb_apikeys']
  # }

  ::postgresql::server::grant { 'API DB Connect':
    privilege => 'CONNECT',
    db        => $db_v2_name,
    role      => $db_v2_api_keys_reader_username,
  }

}