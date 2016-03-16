# Install a basic munin client
class munin::client::base inherits munin::client::params {
  package { 'munin-node':
    ensure => installed
  }
  service { 'munin-node':
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    require    => Package[munin-node],
  }
  file {'/etc/munin':
    ensure => directory,
    mode   => '0755',
    owner  => root,
    group  => 0,
  }
  file {'/etc/munin/munin-node.conf':
    content => template("${module_name}/munin-node.conf.erb"),
    # this has to be installed before the package, so the postinst can
    # boot the munin-node without failure!
    before  => Package['munin-node'],
    notify  => Service['munin-node'],
    mode    => '0644',
    owner   => root,
    group   => 0,
  }
  $host = $munin::host ? {
    '*'      => $::fqdn,
    default  => $munin::host
  }
  munin::register { $::fqdn:
    host        => $host,
    port        => $munin::port,
    use_ssh     => $munin::use_ssh,
    description => $munin::description,
    group       => $munin::munin_group,
    config      => [ 'use_node_name yes', 'load.load.warning 5',
      'load.load.critical 10'],
    export_tag  => $munin::export_tag,
  }
  include munin::plugins::base
}
