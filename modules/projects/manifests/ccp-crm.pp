class projects::ccp-crm {
  include heroku

  require postgresql

  package { [
    'chromedriver'
    ]:
      ensure => latest,
  }

  $ccp_ruby_version = '2.2.2'
  $ccp_node_version = 'v0.12.0'

  boxen::project { 'ccp-crm':
    redis         => true,
    postgresql    => true,
    ruby          => $ccp_ruby_version,
    nginx         => true,
    nodejs        => $ccp_node_version,
    source        => 'CaliforniaCleanPower/ccp-crm',
    dir           => "${boxen::config::srcdir}/exygy/ccp-crm"
  }

  file { "${boxen::config::srcdir}/exygy/ccp-crm/config/database.yml":
      content => template('projects/shared/database.yml'),
      require => Repository["${boxen::config::srcdir}/exygy/ccp-crm"],
      replace => 'no'
  }

  boxen::env_script { 'redis_provider':
    ensure   => $ensure,
    content  => template('projects/shared/redis_provider.sh.erb'),
    priority => 'lowest',
  }

  ## rbenv-installed gems cannot be run in the boxen installation environment
  ## which uses the system ruby. The environment must be cleared (env -i)
  ## so an installed ruby (and gems) can be used in a new shell.
  ## env -i also clears out SHELL, so it must be defined when running commands.

  $base_environment = "env -i SHELL=/bin/bash /bin/bash -c 'source /opt/boxen/env.sh &&"
  $bundle = "$base_environment RBENV_VERSION=${ccp_ruby_version} bundle"

  ## NOTE: don't forget the trailing single quote in the command!
  ## e.g.
  ## command => "${bundle} install'"

  ## bundle install
  exec { 'bundle install ccp':
    provider  => 'shell',
    command   => "${bundle} install'",
    cwd       => "${boxen::config::srcdir}/exygy/ccp-crm",
    require   => [
      Ruby[$ccp_ruby_version],
      Ruby_Gem["bundler for all rubies"],
      Service['postgresql']
    ],
    unless    => "${bundle} check'",
    timeout   => 1800
  }

  ## rake db:setup
  exec { 'rake db:setup ccp':
    provider  => 'shell',
    command   => "${bundle} exec rake db:setup'",
    cwd       => "${boxen::config::srcdir}/exygy/ccp-crm",
    require   => [
      File["${boxen::config::srcdir}/exygy/ccp-crm/config/database.yml"],
      Exec['bundle install ccp']
    ]
  }

  exec { 'overcommit install ccp':
    provider  => 'shell',
    command   => "${bundle} exec overcommit --install --force && rm .git/hooks/post-checkout .git/hooks/commit-msg'",
    cwd       => "${boxen::config::srcdir}/exygy/ccp-crm",
    require   => [
      Exec['bundle install ccp'],
      Exec['npm install']
    ]
  }

  exec { 'npm install':
    provider => 'shell',
    command  => "$base_environment npm install'",
    cwd      => "${boxen::config::srcdir}/exygy/ccp-crm",
    require  => Nodejs[$ccp_node_version]
  }
}
