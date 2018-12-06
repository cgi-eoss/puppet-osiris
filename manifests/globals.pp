# Class for setting cross-class global overrides.
class osiris::globals (
  $manage_package_repo                   = true,

  # Base URL for osiris::proxy
  $base_url                              = "http://${facts['fqdn']}",
  $drupal_url                            = 'https://osiris.example.com',

  # Context paths for reverse proxy
  $context_path_geoserver                = '/geoserver',
  $context_path_resto                    = '/resto',
  $context_path_webapp                   = '/app',
  $context_path_wps                      = '/secure/wps',
  $context_path_api_v2                   = '/secure/api/v2.0',
  $context_path_monitor                  = '/monitor',
  $context_path_logs                     = '/logs',
  $context_path_eureka                   = '/eureka',
  $context_path_analyst                  = '/analyst',
  $context_path_broker                   = '/broker',

  # System user
  $user                                  = 'osiris',
  $group                                 = 'osiris',

  # Hostnames and IPs for components
  $db_hostname                           = 'osiris-db',
  $drupal_hostname                       = 'osiris-drupal',
  $geoserver_hostname                    = 'osiris-geoserver',
  $proxy_hostname                        = 'osiris-proxy',
  $webapp_hostname                       = 'osiris-webapp',
  $wps_hostname                          = 'osiris-wps',
  $server_hostname                       = 'osiris-server',
  $monitor_hostname                      = 'osiris-monitor',
  $resto_hostname                        = 'osiris-resto',
  $broker_hostname                       = 'osiris-broker',
  $default_gui_hostname                  = 'osiris-worker',
  $ui_hostname                           = 'osiris-ui',
  $kubernetes_master_hostname            = 'fskubermaster',

  $hosts_override                        = {},

  # All classes should share this database config, or override it if necessary
  $osiris_db_name                        = 'osiris',
  $osiris_db_v2_name                     = 'osiris_v2',
  $osiris_db_username                    = 'osirisuser',
  $osiris_db_password                    = 'osirispass',
  $osiris_db_resto_name                  = 'osiris_resto',
  $osiris_db_resto_username              = 'osirisresto',
  $osiris_db_resto_password              = 'osirisrestopass',
  $osiris_db_resto_su_username           = 'osirisrestoadmin',
  $osiris_db_resto_su_password           = 'osirisrestoadminpass',
  $osiris_db_zoo_name                    = 'osiris_zoo',
  $osiris_db_zoo_username                = 'osiriszoo',
  $osiris_db_zoo_password                = 'osiriszoopass',

  # SSO configuration
  $username_request_header               = 'REMOTE_USER',
  $email_request_header                  = 'REMOTE_EMAIL',

  # Eureka config
  $serviceregistry_user                  = 'osiriseureka',
  $serviceregistry_pass                  = 'osiriseurekapass',

  # App server config for HTTP and gRPC
  $serviceregistry_application_port      = 8761,
  $server_application_port               = 8090,
  $worker_application_port               = 8091,
  $zoomanager_application_port           = 8092,
  $server_grpc_port                      = 6565,
  $worker_grpc_port                      = 6566,
  $zoomanager_grpc_port                  = 6567,

  # Geoserver config
  $geoserver_port                        = 9080,
  $geoserver_stopport                    = 9079,
  $geoserver_osiris_username             = 'osirisgeoserver',
  $geoserver_osiris_password             = 'osirisgeoserverpass',

  # Resto config
  $resto_osiris_username                 = 'osirisresto',
  $resto_osiris_password                 = 'osirisrestopass',

  # Broker config
  $broker_osiris_username                = 'osirisbroker',
  $broker_osiris_password                = 'osirisbrokerpass',

  # monitor config
  $grafana_port                          = 8089,
  $monitor_data_port                     = 8086,

  # graylog config
  $graylog_secret                        = 'bQ999ugSIvHXfWQqrwvAomNxaMsErX6I4UWicpS9ZU8EDmuFnhX9AmcoM43s4VGKixd2f6d6cELbRuPWO5uayHnBrBbNWVth',
  # sha256 of graylogpass:
  $graylog_sha256                        = 'a7fdfe53e2a13cb602def10146388c65051c67e60ee55c051668a1c709449111',
  $graylog_port                          = 8087,
  $graylog_context_path                  = '/logs',
  $graylog_api_path                      = '/logs/api',
  $graylog_gelf_tcp_port                 = 12201,
  $graylog_api_osiris_username           = 'osirisgraylog',
  $graylog_api_osiris_password           = 'osirisgraylogpass',

  $enable_log4j2_graylog                 = false,

  # API Proxy config
  $osiris_db_v2_api_keys_table           = 'keytable',
  $osiris_db_v2_api_user_table           = 'usertable',
  $osiris_db_v2_api_keys_reader_username = 'username',
  $osiris_db_v2_api_keys_reader_password = 'password',
  $proxy_dbd_db                          = 'osirisdb',
  $proxy_dbd_port                        = 10000,
  $proxy_dbd_dbdriver                    = 'dbdriver',
  $proxy_dbd_query                       = 'dbquery',
) {

  # Alias reverse-proxy hosts via hosts file
  ensure_resources(host, $hosts_override)

  # Setup of the repo only makes sense globally, so we are doing this here.
  if($manage_package_repo) {
    require ::osiris::repo
  }
}
