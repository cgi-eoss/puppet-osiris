class osiris::ui (
  $app_path = '/var/www/html/',
) {

  require ::osiris::globals

  contain ::osiris::common::apache

  ensure_packages(['osiris-ui'], {
    ensure => 'latest',
    name   => 'osiris-ui',
    tag    => 'osiris',
  })

  $directories = [
    {
      'provider'        => 'location',
      'path'            => '/analyst',
      'custom_fragment' => ' RewriteEngine On
		# If an existing asset or directory is requested go to it as it is
		RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -f [OR]
		RewriteCond %{DOCUMENT_ROOT}%{REQUEST_URI} -d
		RewriteRule ^ - [L]
		# If the requested resource does not exist, use index.html
		RewriteRule ^ /analyst/index.html'
    }
  ]

  ::apache::vhost { 'osiris-ui':
    port        => '80',
    servername  => 'osiris-ui',
    docroot     => $app_path,
    directories => $directories
  }

}

