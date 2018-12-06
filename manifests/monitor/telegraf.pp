class osiris::monitor::telegraf (
  $influx_host = 'osiris-monitor',
  $influx_port = '8086',
  $influx_db   = 'osiris',
  $influx_user = 'osiris_user',
  $influx_pass = 'osiris_pass'
) {

  require ::osiris::globals
  require ::epel

  $real_influx_host = pick($influx_host, $osiris::globals::monitor_hostname)
  $real_influx_port = pick($influx_port, $osiris::globals::monitor_data_port)

  class { '::telegraf':
    hostname => $::hostname,
    outputs  => {
      'influxdb' => {
        'urls'     => [ "http://${real_influx_host}:${real_influx_port}" ],
        'database' => $influx_db,
        'username' => $influx_user,
        'password' => $influx_pass,
      }
    },
    inputs   => {
      'cpu' => {
        'percpu'   => true,
        'totalcpu' => true,
      },
    }
  }
}
