class osiris::common::docker (
) {

  require ::osiris::common::user
  require ::osiris::globals

  class { '::docker':
    docker_users => [$osiris::globals::user],
  }

}

