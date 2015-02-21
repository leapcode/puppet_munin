# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.
# Adapted and improved by admin(at)immerda.ch

# configure a munin node
class munin::client {

  case $::operatingsystem {
    openbsd: { include munin::client::openbsd }
    debian,ubuntu: { include munin::client::debian }
    gentoo: { include munin::client::gentoo }
    centos: { include munin::client::base }
    default: { include munin::client::base }
  }
  if $munin::manage_shorewall {
    class{'shorewall::rules::munin':
      munin_port       => $munin::port,
      munin_collector  => delete($munin::allow,'127.0.0.1'),
      collector_source => $munin::shorewall_collector_source,
    }
  }
}
