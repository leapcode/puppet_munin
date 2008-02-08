# plugin.pp - configure a specific munin plugin
# Copyright (C) 2007 David Schmitt <david@schmitt.edv-bus.at>
# See LICENSE for the full license granted to you.

class munin::plugin::scriptpaths {
	case $operatingsystem {
		gentoo: {	
            $script_path =  "/usr/libexec/munin/plugins"
			}
		debian: {		
            $script_path =  "/usr/share/munin/plugins"
			}
		centos: {		
            $script_path =  "/usr/share/munin/plugins"
			}
		default: {
            $script_path =  "/usr/share/munin/plugins"
		}
	}
}


define munin::plugin (
	$ensure = "present",
	$script_path_in = '',
	$config = '')
{

    include munin::plugin::scriptpaths
	#$script_path = $script_path_in ? { '' => $script_path, default => $script_path_in }

	$plugin_src = $ensure ? { "present" => $name, default => $ensure }
	debug ( "munin_plugin: name=$name, ensure=$ensure, script_path=$script_path" )
	$plugin = "/etc/munin/plugins/$name"
	$plugin_conf = "/etc/munin/plugin-conf.d/$name.conf"
	case $ensure {
		"absent": {
			debug ( "munin_plugin: suppressing $plugin" )
			file { $plugin: ensure => absent, } 
		}
		default: {
			debug ( "munin_plugin: making $plugin using src: $plugin_src" )
			file { $plugin:
			    ensure => "$script_path/${plugin_src}",
				require => Package['munin-node'],
				notify => Service['munin-node'];
			}
		}
	}
	case $config {
		'': {
			debug("no config for $name")
			file { $plugin_conf: ensure => absent }
		}
		default: {
			case $ensure {
				absent: {
					debug("removing config for $name")
					file { $plugin_conf: ensure => absent }
				}
				default: {
					debug("creating $plugin_conf")
					file { $plugin_conf:
						content => "[${name}]\n$config\n",
						mode => 0644, owner => root, group => 0,
					}
				}
			}
		}
	}
}

define munin::remoteplugin($ensure = "present", $source, $config = '') {
	case $ensure {
		"absent": { munin::plugin{ $name: ensure => absent } }
		default: {
			file {
				"/var/lib/puppet/modules/munin/plugins/${name}":
					source => $source,
					mode => 0755, owner => root, group => 0;
			}
			munin::plugin { $name:
				ensure => $ensure,
				config => $config,
				script_path => "/var/lib/puppet/modules/munin/plugins",
			}
		}
	}
}

class munin::plugins::base {
    include munin::plugin::scriptpaths

	case $operatingsystem {
		centos: {		
		    file {
			[ "/etc/munin/plugins", "/etc/munin/plugin-conf.d" ]:
				source => "puppet://$servername/munin/empty",
				ensure => directory, checksum => mtime,
				recurse => true, purge => true, force => true, 
				mode => 0755, owner => root, group => 0;
			"/etc/munin/plugin-conf.d/munin-node":
				ensure => present, 
				mode => 0644, owner => root, group => 0;
		    }
		}

		default: {
		    file {
			[ "/etc/munin/plugins", "/etc/munin/plugin-conf.d" ]:
				source => "puppet://$servername/munin/empty",
				ensure => directory, checksum => mtime,
				recurse => true, purge => true, force => true, 
				mode => 0755, owner => root, group => 0,
				notify => Service['munin-node'];
			"/etc/munin/plugin-conf.d/munin-node":
				ensure => present, 
				mode => 0644, owner => root, group => 0,
				notify => Service['munin-node'],
                before => Package['munin-node'];
		    }
		}
	}
}

# handle if_ and if_err_ plugins
class munin::plugins::interfaces inherits munin::plugins::base {

	$ifs = gsub(split($interfaces, " "), "(.+)", "if_\\1")
	$if_errs = gsub(split($interfaces, " "), "(.+)", "if_err_\\1")
	plugin {
		$ifs: ensure => "if_";
		$if_errs: ensure => "if_err_";
	}
}

class munin::plugins::linux inherits munin::plugins::base {

	plugin {
		[ df_abs, forks, iostat, memory, processes, cpu, df_inode, irqstats,
		  netstat, open_files, swap, df, entropy, interrupts, load, open_inodes,
		  vmstat
		]:
			ensure => present;
		acpi: 
			ensure => $acpi_available;
	}

	include munin::plugins::interfaces
}

class munin::plugins::debian inherits munin::plugins::base {

	plugin { apt_all: ensure => present; }

}

class munin::plugins::vserver inherits munin::plugins::base {

	plugin {
		[ netstat, processes ]:
			ensure => present;
	}

}

class munin::plugins::gentoo inherits munin::plugins::base {
    file { "$script_path/gentoo_lastupdated":
            source => "puppet://$servername/munin/plugins/gentoo_lastupdated",
            ensure => file,
            mode => 0755, owner => root, group => 0;
    }

    plugin{"gentoo_lastupdated": ensure => present;}
}

class munin::plugins::centos inherits munin::plugins::base {
}

class munin::plugins::selinux inherits munin::plugins::base {
    file { "$script_path/selinuxenforced":
            source => "puppet://$servername/munin/plugins/selinuxenforced",
            ensure => file,
            mode => 0755, owner => root, group => 0;
    }

    plugin{"selinuxenforced": ensure => present;}
}

define munin::plugins::deploy ($source = '', $enabled = 'true') {
    $real_source = $source ? {
        ''  =>  "munin/plugins/$name",
        default => $source
    }
    include munin::plugins::scriptpaths
    file { "munin_plugin_${name}:
            path => "$script_path/$name",
            source => "puppet://$servername/$real_source",
            ensure => file,
            mode => 0755, owner => root, group => 0;
    }

    if $enabled {
        plugin{$name: ensure => present }
    }
}

class munin::plugins::dom0 inherits munin::plugins::base {
    munin::plugins::deploy { "xen": }
    munin::plugins::deploy { "xen-cpu": }
    munin::plugins::deploy { "xen_memory": }
    munin::plugins::deploy { "xen_vbd": }
}

class munin::plugins::domU inherits munin::plugins::base {
    plugin { if_eth0: ensure => "if_" }
}

class munin::plugins::djbdns inherits munin::plugins::base {
    munin::plugins::deploy { "tinydns": }
}

class munin::plugins::postgres inherits munin::plugins::base {
    munin::plugins::deploy { "pg_conn": }
    munin::plugins::deploy { "pg__connections": enabled => false }
    munin::plugins::deploy { "pg__locks": enabled => false }
}
