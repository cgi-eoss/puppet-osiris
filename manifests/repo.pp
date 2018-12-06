class osiris::repo (
  $location
) {
  case $::osfamily {
    'RedHat', 'Linux': {
      class { 'osiris::repo::osiris': }
    }
    default: {
      fail("Unsupported managed repository for osfamily: ${::osfamily}, operatingsystem: ${::operatingsystem}, module ${module_name} currently only supports managing repos for osfamily RedHat")
    }
  }
}