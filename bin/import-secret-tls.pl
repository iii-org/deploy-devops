#!/usr/bin/perl
# import secret-tls script
#
# Usage:	import-secret-tls.pl <tls_name> <cert_file> <key_file> [namespace]
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0]) || !defined($ARGV[1]) || !defined($ARGV[2])) {
	print("Usage:	$prgname <tls_name> <cert_file> <key_file> [namespace]\n");
	exit;
}
$logfile = "$Bin/$prgname.log";

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$tls_name = $ARGV[0];
$cert_file = $ARGV[1];
$key_file = $ARGV[2];
$namespace = defined($ARGV[3])?'-n '.$ARGV[3]:'';

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $$cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("kubectl [$cmd_kubectl] is not exist!!!\n");
	exit;
}

if (!-e $cert_file) {
	print("cert_file [$cert_file] is not exist!!!\n");
	exit;
}

if (!-e $key_file) {
	print("key_file [$key_file] is not exist!!!\n");
	exit;
}

# Get secret-tls info
$cmd = "$cmd_kubectl get secret $tls_name $namespace";
$cmd_msg = `$cmd 2>&1`;
#devops-iiidevops-tls   kubernetes.io/tls   2      12m
if (index($cmd_msg, 'kubernetes.io/tls')>0) {
	$cmd = "$cmd_kubectl delete secret $tls_name $namespace";
	$cmd_msg = `$cmd 2>&1`;	
	log_print("-----\n$cmd_msg-----\n");
}

# Add secret-tls into K8s default namespace
$cmd = "$cmd_kubectl create secret tls $tls_name --cert=$cert_file --key=$key_file $namespace";
$cmd_msg = `$cmd 2>&1`;
log_print("-----\n$cmd_msg-----\n");
exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}