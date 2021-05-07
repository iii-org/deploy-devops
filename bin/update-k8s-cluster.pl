#!/usr/bin/perl
# update Kubernetes cluster script (Run @first_node)
#
# Check $nfs_dir/deploy-config/*.ready
#
use FindBin qw($Bin);
$|=-1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check runtime user
$cmd = "whoami";
$cmd_msg = `$cmd 2>&1`;
$chk_key = 'rkeuser';
if (index($cmd_msg, $chk_key)<0) {
	log_print("Must use 'rkeuser' user to join K8s cluster!\n");
	exit;
}

# Check my_ip
$cmd = "ip a";
$cmd_msg = `$cmd 2>&1`;
$chk_key = $ARGV[1];
if (index($cmd_msg, $chk_key)<0) {
	log_print("My IP [$chk_key] is not existed in ip list!\n\n$cmd_msg\n");
	exit;
}

