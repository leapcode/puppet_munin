# host.pp - the master host of the munin installation
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

# WARNING: this class should not be included directly. See the 'munin' class.
class munin::host {

  package {'munin': ensure => installed, }

  Concat::Fragment <<| tag == $munin::export_tag |>>

  concat::fragment{'munin.conf.header':
    target => '/etc/munin/munin.conf',
    source => [ "puppet:///modules/site_munin/config/host/${::fqdn}/munin.conf.header",
                "puppet:///modules/site_munin/config/host/munin.conf.header.${::operatingsystem}.${::operatingsystemmajrelease}",
                "puppet:///modules/site_munin/config/host/munin.conf.header.${::operatingsystem}",
                'puppet:///modules/site_munin/config/host/munin.conf.header',
                "puppet:///modules/munin/config/host/munin.conf.header.${::operatingsystem}.${::operatingsystemmajrelease}",
                "puppet:///modules/munin/config/host/munin.conf.header.${::operatingsystem}",
                'puppet:///modules/munin/config/host/munin.conf.header' ],
    order  => 05,
  }

  concat{ '/etc/munin/munin.conf':
    owner => root,
    group => 0,
    mode  => '0644',
  }

  include munin::plugins::muninhost

  if $munin::cgi_graphing {
    class {'munin::host::cgi':
      owner => $munin::cgi_owner,
    }
  }

  # from time to time we cleanup hanging munin-runs
  cron { 'munin_kill':
    command => 'if $(ps ax | grep -v grep | grep -q munin-run); then killall munin-run; fi',
    minute  => ['4', '34'],
    user    => 'root',
  }

  if $munin::manage_shorewall {
    include shorewall::rules::out::munin
  }
}
