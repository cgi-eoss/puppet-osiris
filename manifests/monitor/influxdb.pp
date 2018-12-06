class osiris::monitor::influxdb (
  $db_name           = 'osiris',
  $db_username       = 'osiris_user',
  $db_password       = 'osiris_pass',
  $monitor_data_port = '8086'
) {

  require ::osiris::globals
  require ::epel

  $real_monitor_data_port = pick($monitor_data_port, $osiris::globals::monitor_data_port)

  class { 'influxdb::server':
    http_bind_address => ":$real_monitor_data_port",
  }
}
