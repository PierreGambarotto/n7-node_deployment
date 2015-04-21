# == Class: node_deployment
#
# Full description of class node_deployment here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the function of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'node_deployment':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Pierre Gambarotto <pierre.gambarotto@enseeiht.fr>
#
# === Copyright
#
# Copyright 2015 Pierre Gambarotto
#
class node_deployment (   
  $ensure_service = false,    
  $directory = "/usr/local/${app_name}",
  $url = $fqdn,     
  $port = 80,       
  $ssl = false,     
  $ssl_cert = undef,               # error if none && ssl
  $ssl_key = undef,                # idem
  $username = $name,
  $app_name = $name,
  $ssh_login_keytype = undef,
  $ssh_login_pubkey = undef,
  $ssh_deploy_privatekey = undef,  # generate
  $ssh_deploy_pubkey = undef,      # generate
  $mongodb_name = undef,           # no database
  $upstream_port = 3000,
  ){

  package{git:
    ensure => present
  }

  class { nginx: }
  class {nodejs: 
    manage_repo => true # package more recent than distro
  }

  package {'pm2':
    provider => 'npm',
    ensure => present
  }
  if ($mongodb_name){
    class{'::mongodb::globals':
      manage_package_repo => true,
    } ->
    class {'::mongodb::server':
      # todo : enable auth
    } ->
    class {'::mongodb::client':} ->
    mongodb::db {$mongodb_name:
      user => $app_name
    }
  }
    # to build node dependancies

  $dependancies = [build-essential, python]
  package{$dependancies:
    ensure => present
  }


  # user to run the service
  user{$username:
    ensure => present,
    comment => "rh++ web service",
    home => $directory,
    shell => '/bin/bash',
    purge_ssh_keys => true,
    managehome => true,
  }

  if ($ssh_login_keytype and $ssh_login_pubkey){
    ssh_authorized_key{"manager of ${app_name}":
      user => $username,
      type => $ssh_login_keytype,
      key => $ssh_login_pubkey
    }
  }

  if ($ensure_service){
    exec{"generates pm2 init script for user ${username}":
      require => Package[pm2],
      provider => shell,
      command => "/usr/bin/pm2 startup -s --no-daemon -u ${username}",
      creates => "/etc/init.d/pm2-init.sh"
    }
  }

  # nginx host as proxy
  nginx::resource::upstream {$app_name:
    members => [ "localhost:${upstream_port}" ]
  }

  nginx::resource::vhost{$url:
    require => Ssl::Cert[$ssl_host],
    ssl => $ssl,
    listen_port => $port,
    ssl_port => $port,
    proxy => "http://${app_name}",
    ssl_cert => $ssl_cert,
    ssl_key => $ssl_key
  }    
}
