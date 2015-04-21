node 'test.enseeiht.fr' {
  include sshd, timezone, locale


  locale::set{"fr_FR.UTF-8":}

# ssh authentication with sshkey only
  augeas { "sshd_config_key_only":
    changes => ["set /files/etc/ssh/sshd_config/PasswordAuthentication no"],
    require => File["/etc/ssh/sshd_config"],
    notify => Service[ssh]
  }

# ssh root access

  sshd::import_userkey{"pierre.gambarotto@enseeiht.fr":}
  sshd::import_userkey{"alexei.stoukov@imft.fr":}

  sshd::add_key{"pierre.gambarotto@enseeiht.fr":}
  sshd::add_key{"alexei.stoukov@imft.fr":}

# binaries : git, nodejs/npm, mongodb, nginx, pm2

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

  class{'::mongodb::globals':
    manage_package_repo => true,
  } ->
  class {'::mongodb::server':
  # todo : enable auth
  } ->
  class {'::mongodb::client':}

# to build node dependancies

  $dependancies = [build-essential, python]
  package{$dependancies:
    ensure => present
  }


# for each application :
  # service : start or not
  # service to launch app if needed, with url:port : use pm2 with nginx in front
  # url, port, ssl or not (for nginx)
  # upstream_port, default 3000
  # number of workers (for pm2)
  # application directory
  $rhpp_dir = '/usr/local/rhpp'

  $url = $fqdn # default
  $port = 443 # default corresponding to ssl
  $app_name = 'rhws' 
  $username = 'rhws' # default : $app_name

  $ensure_service = true # default, generate startup script

  exec{"generates pm2 init script for user ${username}":
    require => Package[pm2],
    provider => shell,
    logoutput => true,
    timeout => 20,
    command => "/usr/bin/pm2 startup -s --no-daemon -u ${username}",
    creates => "/etc/init.d/pm2-init.sh"
  }

# if ssl
  $ssl_host = 'wildcard.enseeiht.fr'
  include ssl
  ssl::cert{$ssl_host:
    chain => true
  }

  $ssl_cert = "$ssl::params::cert_path/${ssl_host}_cert.pem"
  $ssl_key = "$ssl::params::key_path/${ssl_host}.key"
  # list of admins (email, ssh_authorized_key ressource)

  # user to run the service
  user{$username:
    ensure => present,
    comment => "rh++ web service",
    home => $rhpp_dir,
    shell => '/bin/bash',
    managehome => true,
  }

  ssh_authorized_key {'pierre.gambarotto@enseeiht.fr':
    user => $username,
    type => 'ssh-dss',
    key => 'AAAAB3NzaC1kc3MAAACBAI7+JDhzMZR1tzOEtrCDOxOz3rB2xJ5sWvt0sXGGUzEX5D0IZ3oLkKqfz1mQG4SOTwts1eNGf12bwGeXGgkbRlBSAt3oREyYYrJe5seDr+OiPEpO+i7LENFukEggCp8BvKS/QZwPpp7oDTbr2XJrLdpFyn02ULZvGcIeHnFQLtRZAAAAFQD7AUfxD782fQ+aFO9pltV88706dwAAAIA5fI85bCeyq+U05uouOWXkvqetcgetMFRAxPv45f473Y4/lWkZZxfT7MAezcUfedAmHzkiOsrGzYO+HjKyOCqnLeNuL17cGHrx+NlSeDS3RRBIIC4HBrDKzfYkzm+vZhgFVud6BmcizWPF6UxrBKqs+q+sg7WXeES0kYDNrjjWbgAAAIAdtmtkVDTwoBx734SxixY9oGQOlGFuL/6houqTFuoi3EprSgjD+ug4CDzPvrQ8ICdrx2FmJr2jxU5cCFtSP1Lq8PkKca+caUn/lC7fcnrm2tflYxLtHj+926tJvWiFOsFdt73aMgDRbH5AKeSk+HlycTyNWMlDAI1dFrRQhH2WyQ=='
  }

  # ssh private key to deploy from upstream git repository

  file{"$rhpp_dir/.ssh/id_rsa":
    owner => $username,
    group => $username,
    mode => 0600,
    content => "-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAqfrPk1nb3ETwuFXHu8nx2y7bJ/JTzl/OspVNXPRG8huyH7YJ
R1s59kpRiAnpfLYmk/6mieNuNH4BTTRqJNBlLtPLzUF3uc+YuyptrdPfWNLBud6U
KZAcNduVkIoFJkrcHtLLK0gvKeAozJ4plMaKpXGV2zEFvrbA1/02W26n7dVnwatd
EQIXVdM2Bh4VqpuhNtxN7OXFOW3kvm7tTnCBfVS3dBS/Qp6SAb7ar2Q2SYLcKEWQ
LTbVyv2EpC3xNE9yrH9THHAcL26K9+P1oZPmfQnH/kjqmEEIWqVU2v4xu8sfVTmy
KBcb3uYe09HXqrITCKWuq6WyLtn3GsWMm90XOwIDAQABAoIBAQCEPVZEQsJjiVbl
cgbjt+ZrKPbjCwncInlCQhlf2cNgE9/t/8cUNorPa14mwd9eYK9+r7yMxd01BVqp
3788SMyPM8L4OpiUfEdMRWPyukSma8C/g8Qs2aq40852FoqPEepSKJhbYdsfbv8O
wXWEAzpWIBn/3xGjH7bD0oD5fQs0YW+EbWWLbA+cAJfEDPlKxO78bCTj/2/E4Npx
xRywhxrLJRUSLjHD4+uEwgiTNOiZwxLJZ1tfWrLMxri6nEdsj7aAakYfg32w/74G
b6jVaHc9QXUj8L8/E4SAipWlrH5QCvMiVQeV8mZSnpFSpVnprXukKQzNCqWK+1YM
GU4RqvzBAoGBANfdBnswf3nXianhAcD8Ml8PC260/sGlhc08FkPCplvoRtC2Gxd+
nlK1B46uAn6D2MIh48SUheEqgML/D84PdzXoWB4rnaCdunD1pZKL4aiK9fmuMftw
dylYgP9rDTcCcUm74dgiEJusRmzQUcYfXgiOjj2zUFRkY9T8fJ5ijLSxAoGBAMmV
v+9/9WjsWzj0O5CK86sMEwWZG2d0IXR5gGf2t7P/CbPkq64AUx3YsXxmxzFlqjMG
7G5Njo0Of+HIXCgFJYFILl0wpBAJiYdOAH3zoyz/BJmyKPlCL2Cjz+4VgKuHxHGv
WrbKmNnjNRmhdQUBt1ROqqba1TpVo4ciIlvG4/WrAoGALI+zG9EqL6PgBlKtwwIM
//SiHot8n8sksPZ7fid7ojN0EvfU5ee8lURLuBeR6j4bjA/k7hre/FmC1T5EK/yj
VlyNfETyuEp3R4ReVr9LqThuiMl+BfL0lnNvxcp6ouV9L4R6ndyCYzCQJTxn9Sda
iReso24V4iYLOdeZfjTH6TECgYBl81eMECIUu5zzNAo/8xaDRmsEZMfITaJx3tVD
PzLvVKgalCcDrGRc7u/so6pQYENw5SqEKrNSwaeJkCSTlO6/8LqKJQSEm94zUQ7M
pIC9TAiOlt1EGuYNMSwDFFrr5ZFDkdUGJ3agk9mSKecd7h1DBTongvteMluvB2Nr
GS7HWwKBgDHtRVPWg5PV5xoPJwsEzYz3tiDFNmpKxqnXPOQKlcIYhYrisb/4/njB
Xa0hups6ayjCeZ2Ul2DRE9MEnPb0b7xfAxSVjt1uqea2H69yWFUpRO6wJyPOD/Wa
I6qp6uVA0GPjT3cW5T5ZeURY71dkwbZ+A4nryBF8UetnHDS/o+cU
-----END RSA PRIVATE KEY-----"
  
  }

  # ssh pub key, for the user to upload on a git server
  file{"$rhpp_dir/.ssh/id_rsa.pub":
    owner => $username,
    group => $username,
    mode => 0644,
    content => "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCp+s+TWdvcRPC4Vce7yfHbLtsn8lPOX86ylU1c9EbyG7IftglHWzn2SlGICel8tiaT/qaJ4240fgFNNGok0GUu08vNQXe5z5i7Km2t099Y0sG53pQpkBw125WQigUmStwe0ssrSC8p4CjMnimUxoqlcZXbMQW+tsDX/TZbbqft1WfBq10RAhdV0zYGHhWqm6E23E3s5cU5beS+bu1OcIF9VLd0FL9CnpIBvtqvZDZJgtwoRZAtNtXK/YSkLfE0T3Ksf1MccBwvbor34/Whk+Z9Ccf+SOqYQQhapVTa/jG7yx9VObIoFxve5h7T0deqshMIpa6rpbIu2fcaxYyb3Rc7 root@rhws"
  }


  # mongodb database
  # with default auth, every local access is granted
  $db_name = $app_name # default
  $db_user = $app_name # default
  $db_password = generate('/usr/bin/makepasswd')

  mongodb::db{ $db_name:
    user => $db_user,
    password => $db_password
  }


  # nginx as proxy

  $upstream_port = 3000
  nginx::resource::upstream {$app_name:
    members => [ "localhost:${upstream_port}" ]
  }

  nginx::resource::vhost{$url:
    require => Ssl::Cert[$ssl_host],
    ssl => true,
    listen_port => $port,
    ssl_port => $port,
    proxy => "http://${app_name}",
    ssl_cert => $ssl_cert,
    ssl_key => $ssl_key
  } 
}
