class osiris::common::apache {

  class { ::apache:
    default_vhost => false,
  }

  ::apache::namevirtualhost { '*:80': }

  if $facts['selinux'] {
    ::selinux::boolean { 'httpd_can_network_connect_db':
      ensure => true,
    }

    ::selinux::boolean { 'httpd_can_network_connect':
      ensure => true,
    }

    ::selinux::port { 'php-fpm':
      seltype  => 'http_port_t',
      port     => 9000,
      protocol => 'tcp'
    }

    ::selinux::port { 'osiris-server':
      seltype  => 'http_port_t',
      port     => $osiris::globals::server_application_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'osiris-worker':
      seltype  => 'http_port_t',
      port     => $osiris::globals::worker_application_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'grafana':
      seltype  => 'http_port_t',
      port     => $osiris::globals::grafana_port,
      protocol => 'tcp'
    }

    ::selinux::port { 'graylog':
      seltype  => 'http_port_t',
      port     => $osiris::globals::graylog_port,
      protocol => 'tcp'
    }
  }

}
