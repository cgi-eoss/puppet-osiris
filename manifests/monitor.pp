class osiris::monitor () {

  require ::osiris::globals
  require ::epel

  contain ::osiris::monitor::grafana
  contain ::osiris::monitor::influxdb
  contain ::osiris::monitor::telegraf
  contain ::osiris::monitor::graylog_server

}

