class osiris::common::datadir (
  $data_basedir = '/data'
) {
  require ::osiris::common::user

  # TODO Use nfs server for $data_basedir
  file { $data_basedir:
    ensure  => directory,
    owner   => 'osiris',
    group   => 'osiris',
    mode    => '755',
    recurse => false,
  }
}