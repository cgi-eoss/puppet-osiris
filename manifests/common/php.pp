class osiris::common::php {

  # Repo for updated PHP packages
  require osiris::repo::webtatic

  # PHP 5.6
  class { ::php:
    ensure         => latest,
    manage_repos   => false,
    fpm            => true,
    package_prefix => 'php56w-',
    composer       => true,
    pear           => true,
    extensions     => {
      xml      => {},
      gd       => {},
      pdo      => {},
      mbstring => {},
      pgsql    => {},
    },
    settings       => {
      'PHP/max_execution_time'  => '90',
      'PHP/max_input_time'      => '300',
      'PHP/memory_limit'        => '128M',
      'PHP/post_max_size'       => '32M',
      'PHP/upload_max_filesize' => '32M',
      'Date/date.timezone'      => 'UTC',
    },
    require        => Yumrepo['webtatic']
  }

}
