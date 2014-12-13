#
# munin module
# munin.pp - everything a sitewide munin installation needs
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
#
# Copyright 2008, Puzzle ITC GmbH
# Marcel Haerry haerry+puppet(at)puzzle.ch
# Simon Josi josi+puppet(at)puzzle.ch
#
# This program is free software; you can redistribute
# it and/or modify it under the terms of the GNU
# General Public License version 3 as published by
# the Free Software Foundation.
#
# Parameters:
# $is_server  - determines whether or not to install munin server. munin-node is
#               required for the server so it is always installed.
# $export_tag - tag exported resources so that only the server targeted by that
#               tag will collect them. This can let you install multiple munin
#               servers.
#
# Client-specific parameters:
# $allow, $host, $host_name, $port, $use_ssh, $manage_shorewall,
# $shorewall_collector_source, $description, $munin_group
#
# Server-specific parameters:
# $cgi_graphing, cgi_owner

class munin (
  $is_server                  = false,
  $export_tag                 = 'munin',
  $allow                      = [ '127.0.0.1' ],
  $host                       = '*',
  $host_name                  = $::fqdn,
  $port                       = '4949',
  $use_ssh                    = false,
  $manage_shorewall           = false,
  $shorewall_collector_source = 'net',
  $description                = 'absent',
  $munin_group                = 'absent',
  $cgi_graphing               = false,
  $cgi_owner                  = 'os_default',
) {

  include munin::client

  if $is_server {
    include munin::host
  }
}
