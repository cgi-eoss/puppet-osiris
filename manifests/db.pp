class osiris::db (
  $trust_local_network = false,
) {

  require ::osiris::globals

  contain ::osiris::db::postgresql

}