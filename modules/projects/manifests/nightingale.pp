class projects::nightingale {
  include heroku

  require postgresql

  package { [
    'chromedriver'
    ]:
      ensure => latest,
  }

  $nightingale_ruby_version = '2.2.1'
  $nightingale_node_version = 'v0.12.0'

  boxen::project { 'nightingale':
    redis         => true,
    postgresql    => true,
    ruby          => $nightingale_ruby_version,
    nginx         => true,
    nodejs        => $nightingale_node_version,
    source        => 'seanknox/nightingale'
  }

  file { "${boxen::config::srcdir}/nightingale/.env":
      content => template('projects/nightingale/env.erb'),
      require => Repository["${boxen::config::srcdir}/nightingale"],
      replace => 'no'
  }

  boxen::env_script { 'redis_provider':
    ensure   => $ensure,
    content  => template('projects/nightingale/redis_provider.sh.erb'),
    priority => 'lowest',
  }


  ## rbenv-installed gems cannot be run in the boxen installation environment
  ## which uses the system ruby. The environment must be cleared (env -i)
  ## so an installed ruby (and gems) can be used in a new shell.
  ## env -i also clears out SHELL, so it must be defined when running commands.

  $base_environment = "env -i SHELL=/bin/bash /bin/bash -c 'source /opt/boxen/env.sh &&"
  $bundle = "$base_environment RBENV_VERSION=${nightingale_ruby_version} bundle"

  ## NOTE: don't forget the trailing single quote in the command!
  ## e.g.
  ## command => "${bundle} install'"

  ## bundle install
  exec { 'bundle install nightingale':
    provider  => 'shell',
    command   => "${bundle} install'",
    cwd       => "${boxen::config::srcdir}/nightingale",
    require   => [
      Ruby[$nightingale_ruby_version],
      Ruby_Gem["bundler for all rubies"],
      Service['postgresql']
    ],
    unless    => "${bundle} check'",
    timeout   => 1800
  }

  ## rake db:setup
  exec { 'rake db:setup nightingale':
    provider  => 'shell',
    command   => "${bundle} exec rake db:setup'",
    cwd       => "${boxen::config::srcdir}/nightingale",
    require   => [
      Exec['bundle install nightingale']
    ]
  }

  exec { 'overcommit install nightingale':
    provider  => 'shell',
    command   => "${bundle} exec overcommit --install --force && rm .git/hooks/post-checkout .git/hooks/commit-msg'",
    cwd       => "${boxen::config::srcdir}/nightingale",
    require   => [
      Exec['bundle install nightingale'],
      Exec['npm install']
    ]
  }

  exec { 'npm install':
    provider => 'shell',
    command  => "$base_environment npm install'",
    cwd      => "${boxen::config::srcdir}/nightingale",
    require  => Nodejs[$nightingale_node_version]
  }
}
