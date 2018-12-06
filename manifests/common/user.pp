class osiris::common::user (
  $user  = undef,
  $group = undef,
  $home  = '/home/osiris'
) {

  $uid = pick($user, $osiris::globals::user)
  $gid = pick($group, $osiris::globals::group)

  group { $gid:
    ensure => present,
  }

  user { $uid:
    ensure     => present,
    gid        => $gid,
    managehome => true,
    home       => $home,
    shell      => '/bin/bash',
    system     => true,
    require    => Group[$gid],
  }

}
