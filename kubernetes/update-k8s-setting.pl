#!/usr/bin/perl
# update K8s cluster.yml script
#
# Usage: update-k8s-setting.pl <cmd> <IP> [<role>]
# <cmd> : Initial / Add / Remove / Modify
# <role> (Options) worker(Default), controlplane, etcd, all
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	print("Usage:	$prgname <cmd> <IP> [<role>]\n");
	exit;
}
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$cmd = $ARGV[0];
$node_ip  = $ARGV[1];
$node_role = (defined($ARGV[2]))?$ARGV[2]:'worker';
$yml_file = "$nfs_dir/deploy-config/cluster.yml";

$rke_ver = get_system_ver('rke');
$cluser_tmpl = $hash_rke_cluster_yml{$rke_ver};
if (!$cluser_tmpl) {
	log_print("Unable to find a template that matches this rke version : [$rke_ver]!\n");
	exit;
}

if ($cmd eq 'Initial') {
	gen_cluster_yml($node_ip);
}
elsif ($cmd eq 'Add') {
	add_cluster_yml($node_ip, $node_role);
}
elsif ($cmd eq 'TLS') {
	tls_cluster_yml();
}

exit;


sub gen_cluster_yml {
	my ($p_node_ip) = @_;
	local($cluster_node, $node_role_list, $node_role, $cluster_yml);

	$cluster_node = add_node_yml($p_node_ip, 'controlplane_worker_etcd');
	write_cluster_yml($cluster_node, $ingress_domain_name_tls);

	return;
}

sub tls_cluster_yml {
	my ($msg, $cluster_node_list, $line, $t1, $t_ip, $t_role);

	#Get Node List
	#cat cluster.yml | grep K8s_node
	# K8s_node, 10.20.0.37, controlplane_worker_etcd
	# K8s_node, 10.20.0.36, controlplane_worker_etcd
	$msg = `cat $yml_file | grep K8s_node`;
	$cluster_node_list = '';
	foreach $line (split("\n", $msg)) {
		# K8s_node, 10.20.0.37, controlplane_worker_etcd
		($t1, $t_ip, $t_role) = split(', ', $line);
		$cluster_node_list .= ($cluster_node_list ne '')?"\n":'';
		$cluster_node_list .= add_node_yml($t_ip, $t_role);
	}
	$cluster_node_list .= ($cluster_node_list ne '')?"\n":'';
	write_cluster_yml($cluster_node_list, $ingress_domain_name_tls);

	return;
}

sub add_cluster_yml {
	my ($p_node_ip, $p_node_role) = @_;
	my ($msg, $cluster_node_list, $line, $t1, $t_ip, $t_role);

	#Get Node List
	#cat cluster.yml | grep K8s_node
	# K8s_node, 10.20.0.37, controlplane_worker_etcd
	# K8s_node, 10.20.0.36, controlplane_worker_etcd
	$msg = `cat $yml_file | grep K8s_node`;
	if (index($msg, ' '.$p_node_ip.',')>0) {
		log_print("IP:[$p_node_ip] is already in K8s Cluster!\n$msg\n\n");
		return;
	}
	
	$cluster_node_list = '';
	foreach $line (split("\n", $msg)) {
		# K8s_node, 10.20.0.37, controlplane_worker_etcd
		($t1, $t_ip, $t_role) = split(', ', $line);
		$cluster_node_list .= ($cluster_node_list ne '')?"\n":'';
		$cluster_node_list .= add_node_yml($t_ip, $t_role);
	}
	$cluster_node_list .= ($cluster_node_list ne '')?"\n":'';
	$cluster_node_list .= add_node_yml($p_node_ip, $p_node_role);
	write_cluster_yml($cluster_node_list, $ingress_domain_name_tls);

	return;
}

# Gen node section Exp.
## K8s_node, 10.20.0.95, controlplane_worker_etcd
#- address: 10.20.0.95
#  port: "22"
#  internal_address: 10.20.0.95
#  role:
#  - controlplane
#  - worker
#  - etcd
#  hostname_override: ""
#  user: rkeuser
#  docker_socket: /var/run/docker.sock
# :
# :
sub add_node_yml {
	my ($p_node_ip, $p_role_list) = @_;
	local($cluster_node_tmpl, $cluster_node, $node_role);

	$cluster_node_tmpl = `cat $Bin/cluster_node.tmpl`;
	$node_role = gen_node_role($p_role_list);
	$cluster_node = $cluster_node_tmpl;
	$cluster_node =~ s/%%node_ip%%/$p_node_ip/g;
	$cluster_node =~ s/%%node_role_list%%/$p_role_list/g;
	$cluster_node =~ s/%%node_role%%/$node_role/g;
	
	return($cluster_node);
}

# Gen node role Exp.
#  role:
#  - controlplane
#  - worker
#  - etcd
sub gen_node_role {
	my ($p_role_list) = @_;
	my ($node_role);
	
	$node_role = '';
	if (index($p_role_list, 'controlplane')>=0) {
		$node_role .= "  - controlplane";
	}
	if (index($p_role_list, 'worker')>=0) {
		$node_role .= ($node_role ne '')?"\n":'';
		$node_role .= "  - worker";
	}
	if (index($p_role_list, 'etcd')>=0) {
		$node_role .= ($node_role ne '')?"\n":'';
		$node_role .= "  - etcd";
	}

	return($node_role);
}

# Write full cluster.yml
sub write_cluster_yml {
	my ($p_node_list, $p_tls) = @_;
	my ($rke_ver, $tmpl_file, $cluster_yml_tmpl, $ingress_yml_tmpl, $cluster_yml);

	$rke_ver = get_system_ver('rke');
	$tmpl_file = $hash_rke_cluster_yml{$rke_ver};
	$cluster_yml_tmpl = `cat $Bin/$tmpl_file`;
	if ($p_tls ne '') {
		$ingress_yml_tmpl = `cat $Bin/ingress_tls_yml.tmpl`;
		$ingress_yml_tmpl =~ s/%%ingress_domain_name_tls%%/$p_tls/g;
	}
	else {
		$ingress_yml_tmpl = `cat $Bin/ingress_yml.tmpl`;
	}
	$cluster_yml = $cluster_yml_tmpl;
	$cluster_yml =~ s/%%node_list%%/$p_node_list/g;
	$cluster_yml =~ s/%%ingress%%/$ingress_yml_tmpl/g;
	
	open(FH, '>', $yml_file) or die $!;
	print FH $cluster_yml;
	close(FH);

	return;
}

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}