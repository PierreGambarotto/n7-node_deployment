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
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2015 Your name here, unless otherwise noted.
#
class node_deployment {
  define application(              # default value
  $ensure_service = false,    
  $directory = "/usr/local/${name}",
  $url = $fqdn,     
  $port = 80,       
  $ssl = false,     
  $ssl_cert = undef,               # error if none && ssl
  $ssl_key = undef,                # idem
  $username = $name,
  $app_name = $name,
  $ssh_login_type = undef,
  $ssh_login_pubkey = undef,
  $ssh_deploy_privatekey = undef,  # generate
  $ssh_deploy_pubkey = undef,      # generate
  $mongodb_name = undef,           # no database
  $upstream_port = 3000,
    ){

    notify {debug:
      message => "url: ${url} username: ${username} app_name: ${app_name}"
    }
    
  }
}
