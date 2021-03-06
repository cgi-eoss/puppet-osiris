class osiris::proxy::letsencrypt {
  require ::osiris::common::apache
  require ::epel

  class { ::letsencrypt:
    configure_epel => false,
    email => $osiris::globals::operator_email,
  }

  ::letsencrypt::certonly { $osiris::proxy::vhost_name:
    domains              => [$osiris::proxy::vhost_name],
    plugin               => 'standalone',
    additional_args      => ["--preferred-challenges http-01", "--expand", "--quiet"],
    manage_cron          => true,
    cron_success_command => '/bin/systemctl reload httpd.service',
    suppress_cron_output => true,
    before               => Apache::Vhost[$osiris::proxy::vhost_name],
  }
}
