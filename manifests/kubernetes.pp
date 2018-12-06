class osiris::kubernetes () {

  require ::osiris::globals
  require ::epel

  require ::etcd
  require ::kubernetes::master
  require ::kubernetes::node

  contain ::osiris::kubernetes::master
  contain ::osiris::kubernetes::worker

}

