#!/usr/bin/perl
# update K8s cluster.yml script
#
# Usage: update-k8s-cluster.pl <cmd> <IP> [<role>]
# <cmd> : Initial / Add / Remove / Modify
# <role> (Options) worker(Default), controlplane, etcd, all
#
use FindBin qw($Bin);
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
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$cmd = $ARGV[0];
$node_ip  = $ARGV[1];
$node_role = (defined($ARGV[2]))?$ARGV[2]:'worker';
$yml_file = "$nfs_dir/deploy-config/cluster.yml";
$cluster_yml_tmpl = `cat $Bin/cluster_yml.tmpl`;
$cluster_node_tmpl = `cat $Bin/cluster_node.tmpl`;

if ($cmd eq 'Initial') {
	$msg = gen_cluster_yml($node_ip);
	exit;
}


#Get Node List
#cat cluster.yml | grep K8s_node
# K8s_node, 10.20.0.37, controlplane_worker_etcd
# K8s_node, 10.20.0.36, controlplane_worker_etcd

exit;


sub gen_cluster_yml {
	my ($p_node_ip) = @_;
	local($cluster_node, $node_role_list, $node_role, $cluster_yml);

	$node_role_list = 'controlplane_worker_etcd';
	$node_role = "  - controlplane\n";
	$node_role .= "	- worker\n";
	$node_role .= "	- etcd\n";
	
	$cluster_node = $cluster_node_tmpl;
	$cluster_node =~ s/%%node_ip%%/$p_node_ip/g;
	$cluster_node =~ s/%%node_role_list%%/$node_role_list/g;
	$cluster_node =~ s/%%node_role%%/$node_role/g;
	
	$cluster_yml = $cluster_yml_tmpl;
	$cluster_yml =~ s/%%node_list%%/$cluster_node/g;
	
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