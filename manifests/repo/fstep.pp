# Osiris package repository
class osiris::repo::osiris {
  ensure_resource(yumrepo, 'osiris', {
    ensure          => 'present',
    descr           => 'Osiris',
    baseurl         => $osiris::repo::location,
    enabled         => 1,
    gpgcheck        => 0,
    metadata_expire => '15m',
  })
}