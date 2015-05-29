# exygy-boxen

This is Exygy's incarnation of [GitHub's Boxen](https://boxen.github.com).
Automated Mac provisioning. Use Boxen to setup a robust developer
environment on your Mac in an hour or less (or your money back).

## Before Getting Started
### Boxen on a Fresh Install of OS X

*This guide assumes you are running Boxen on a __clean install__ of
OS X 10.8 (Mountain Lion) or 10.9 (Mavericks). Tested on:*
- *clean OS X 10.8*
- *clean OS X 10.9*
- Command Line Tools or Xcode >= `5.1.0.0.1.1396320587`

### Boxen on an Existing System
There are a few potential conflicts to keep in mind.
Boxen does its best not to get in the way of a dirty system,
but you should check  the following before attempting to install your
boxen on any machine (we do some checks before every Boxen run to try
and detect most of these and tell you anyway):

* Boxen __requires__ at least the Xcode Command Line Tools installed.
* Boxen __will not__ work with an existing rvm install.
* Boxen __may not__ play nice with a GitHub username that includes dash(-)
* Boxen __may not__ play nice with an existing rbenv install.
* Boxen __may not__ play nice with an existing chruby install.
* Boxen __may not__ play nice with an existing homebrew install.
* Boxen __may not__ play nice with an existing nvm install.
* Boxen __recommends__ installing the full Xcode.

## Prerequisites for All Systems

- You have a GitHub account and it has been added to the `exygy` organization.
- If on OS X 10.8, you will need to install the Xcode Command Lines Tools and/or full Xcode.
*(Xcode CLT are installed automatically on OS X 10.9)*

### OS X < 10.9
OS X 10.8 users will need to install Xcode before running Boxen.

1. Install Xcode from the Mac App Store.
1. Open Xcode.
1. Open the Preferences window (`Cmd-,`).
1. Go to the Downloads tab.
1. Install the Command Line Tools.

## Getting Started

To give you a brief overview, we're going to:

* Install dependencies
* Bootstrap your box to use exygy-boxen

## Boxenify me

Install Boxen by either:

* Use the web-based [Boxen Web](https://exygy-boxen-web.herokuapp.com) *(easiest)*, or
* Alternatively, open Terminal.app and do the following:

```bash
sudo mkdir -p /opt/boxen
sudo chown ${USER}:staff /opt/boxen
git clone https://github.com/exygy/exygy-boxen.git /opt/boxen/repo
cd /opt/boxen/repo
script/boxen all
```

Boxen will run for awhile, depending on the speed of your computer. After it
finishes, your provisioning is now complete. Open a new terminal window to
reinitialize your shell and start using your system.

## What You Get

### System stuff:
* Homebrew
* Git *(your GitHub login credentials are encrypted and stored on your local filesystem—no more entering username/password)*
* Hub
* dnsmasq w/ .dev resolver for localhost
* rbenv
* Node.js 0.10.31
* Ruby 1.9.3
* Ruby 2.0.0
* Ruby 2.1.5
* Ruby 2.2.1 _(set as global default)_
* Heroku Toolbelt
* gcc
* ack
* Findutils
* GNU tar
* The Silver Searcher (`ag` command: a faster alternative to `ack`)

### Mac Apps
* Chrome
* Google Drive
* iTerm2
* Virtualbox
* Sublime Text 3 with Engineering (heavily modified VIM+Sublime) setup
* Flowdock

### Shell setup and Environment variables
Boxen ensures it is first in your $PATH so there is no more confusion to where
your Ruby/Python/gem/etc. binary is. Additionally, Boxen setups up handy
shell variables for Boxen and all services installed through Boxen. For example:
* `$BOXEN_HOME`
* `$BOXEN_REDIS_URL`
* `$BOXEN_POSTGRESQL_HOST`
* `$BOXEN_POSTGRESQL_PORT`

Run `boxen --env` to see a full list.

### Including boxen modules from github (boxen/puppet-<name>)

You must add the github information for your added Puppet module into your Puppetfile at the root of your
boxen repo (ex. /path/to/your-boxen/Puppetfile):

    # Core modules for a basic development environment. You can replace
    # some/most of these if you want, but it's not recommended.

    github "repository", "2.0.2"
    github "dnsmasq",    "1.0.0"
    github "gcc",        "1.0.0"
    github "git",        "1.2.2"
    github "homebrew",   "1.1.2"
    github "hub",        "1.0.0"
    github "inifile",    "0.9.0", :repo => "cprice404/puppetlabs-inifile"
    github "nginx",      "1.4.0"
    github "nodejs",     "2.2.0"
    github "ruby",       "4.1.0"
    github "stdlib",     "4.0.2", :repo => "puppetlabs/puppetlabs-stdlib"
    github "sudo",       "1.0.0"

    # Optional/custom modules. There are tons available at
    # https://github.com/boxen.

    github "java",     "1.6.0"

In the above snippet of a customized Puppetfile, the bottom line
includes the Java module from Github using the tag "1.6.0" from the github repository
"[boxen/puppet-java/releases](https://github.com/boxen/puppet-java/releases)".  The function "github" is defined at the top of the Puppetfile
and takes the name of the module, the version, and optional repo location:

    def github(name, version, options = nil)
      options ||= {}
      options[:repo] ||= "boxen/puppet-#{name}"
      mod name, version, :github_tarball => options[:repo]
    end

Now Puppet knows where to download the module from when you include it in your site.pp or mypersonal.pp file:

    # include the java module referenced in my Puppetfile with the line
    # github "java",     "1.6.0"
    include java

### Hiera

Hiera is preferred mechanism to make changes to module defaults (e.g. default
global ruby version, service ports, etc). This repository supplies a
starting point for your Hiera configuration at `config/hiera.yml`, and an
example data file at `hiera/common.yaml`. See those files for more details.

The default `config/hiera.yml` is configured with a hierarchy that allows
individuals to have their own hiera data file in
`hiera/users/{github_login}.yaml` which augments and overrides
site-wide values in `hiera/common.yaml`. This default is, as with most of the
configuration in the example repo, a great starting point for many
organisations, but is totally up to you. You might want to, for
example, have a set of values that can't be overridden by adding a file to
the top of the hierarchy, or to have values set on specific OS
versions:

```yaml
# ...
:hierarchy:
  - "global-overrides.yaml"
  - "users/%{::github_login}"
  - "osx-%{::macosx_productversion_major}"
  - common
```

## Where Boxen lives
Boxen is installed into `/opt/boxen`, as is all software installed
through Boxen (Homebrew, rbenv, phantomenv, nodenv, etc.)
### Homebrew
Homebrew is installed into `/opt/boxen/homebrew`, not the
usual `/usr/local/` path. Any Homebrew package *should*
 work fine, but some packages may have hardcoded `/usr/local/` as an install path.
### rbenv / Ruby
`rbenv` is installed into `/opt/boxen/rbenv`. All ruby
versions are installed into `/opt/rubies`.

## Updating Boxen
Whenever Boxen is run, it will automatically attempt to fetch
the latest version from the [exygy/exygy-boxen](https://github.com/exygy/exygy-boxen) repo.

For more information about the Boxen project, including more details about custom manifests, check out GitHub's official [Boxen page.](https://github.com/boxen/our-boxen)

