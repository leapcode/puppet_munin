# Puppet-Munin

[![Build Status](https://travis-ci.org/duritong/puppet-munin.png?branch=master)](https://travis-ci.org/duritong/puppet-munin)

Munin is a performance monitoring system which creates nice RRD graphs and has
a very easy plugin interface. The munin homepage is http://munin.projects.linpro.no/

## Requirements

   * puppet 2.7 or newer
   * install the `concat` and `stdlib` modules - the munin module depends on functions that are defined and installed via these modules
   * you will need storedconfigs enabled in your puppet setup, to do that you need to add a line to your `puppet.conf` in your `[puppetmasterd]` section which says:

            storeconfigs=true

   * You may wish to immediately setup a `mysql`/ `pgsql` database for your storedconfigs, as
   the default method uses sqlite, and is not very efficient, to do that you need lines
   such as the following below the `storeconfigs=true` line (adjust as needed):

           dbadapter=mysql
           dbserver=localhost
           dbuser=puppet
           dbpassword=puppetspasswd
    
## Usage

Your modules directory will need all the files included in this repository placed under a directory called `munin`.

### Master configuration

To install a master (or server) you need to flip one argument to true in the main class:

      class { 'munin': is_server => true }

If you want cgi graphing you can pass `cgi_graphing => true`. (For CentOS this is enabled in the default header config) for more information, see: http://munin.projects.linpro.no/wiki/CgiHowto

### Client configuration

For every host you wish to gather munin statistics, add the class `munin` to that
node. You will want to set the class parameter `allow` to be the IP(s) of the munin
collector, this defines what IP is permitted to connect to the node, for example:

      node foo {
        class { 'munin': allow => '192.168.0.1'}
      }

for multiple munin collectors, you can pass an array:

      class { 'munin': allow => [ '192.168.0.1', '10.0.0.1' ] }

### Local plugins

If there are particular munin plugins you want to enable or configure, you define them
in the node definition, like follows:

      # Enable monitoring of disk stats in bytes
      munin::plugin { 'df_abs': }

      # Use a non-standard plugin path to use custom plugins
      munin::plugin { 'spamassassin':
        ensure         => present,
        script_path_in => '/usr/local/share/munin-plugins',
      }
    
      # For wildcard plugins (eg. ip_, snmp_, etc.), use the name variable to
      # configure the plugin name, and the ensure parameter to indicate the base
      # plugin name to which you want a symlink, for example:
      munin::plugin { [ 'ip_192.168.0.1', 'ip_10.0.0.1' ]:
        ensure => 'ip_'
      }
    
      # Use a special config to pass parameters to the plugin
      munin::plugin {
        [ 'apache_accesses', 'apache_processes', 'apache_volume' ]:
           ensure => present,
           config => 'env.url http://127.0.0.1:80/server-status?auto'
      }

Note: The plugin must be installed at the client. For listing available plugins run as root `munin-node-configure --suggest`      
      
### External plugins

For deploying plugins which are not available at client, you can fetch them from puppet
master using `munin::plugin::deploy`.

      munin::plugin::deploy { 'redis':
          source => 'munin/plugins/redis/redis_',
          config => ''   # pass parameters to plugin
      }

In this example the file on master would be located in:
    
     {modulepath}/munin/files/plugins/redis/redis_
     
Module path is specified in `puppet.conf`, you can find out your `{modulepath}` easily by tying 
in console `puppet config print modulepath`.


### Multiple munin collectors

If some part of your infrastructure should be graphed by one munin collector,
and another part by a second collector, you can use the parameter $export_tag
to the main class to differentiate which clients and collectors are associated.

For example, here are four nodes: two collectors and two clients. Each
collector is associated with one client:

      node coll1 {
        class { 'munin':
          $is_server  => true,
          $export_tag => 'coll1',
        }
      }

      node client1 {
        class { 'munin':
          $export_tag => 'coll1',
        }
      }

      node coll2 {
        class { 'munin':
          $is_server  => true,
          $export_tag => 'coll2',
        }
      }

      node client2 {
        class { 'munin':
          $export_tag => 'coll2',
        }
      }

### Multiple munin-node instances with Linux-VServer

If you have Linux-Vservers configured, you will likely have multiple munin-node processes
competing for the default port 4949, for those nodes, set an alternate port for munin-node
to run on by putting something similar to the following class parameter:

      class { 'munin': allow => '192.168.0.1', port => '4948' }
