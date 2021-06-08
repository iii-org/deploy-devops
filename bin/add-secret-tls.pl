#!/usr/bin/perl
# add secret-tls script
#
# Usage: sudo add-secret-tls.pl <tls_name> <cert_file> <key_file>
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0] || !defined($ARGV[1] || !defined($ARGV[2])) {
	print("Usage:	sudo $prgname <tls_name> <cert_file> <key_file>\n");
	exit;
}
$logfile = "$Bin/$prgname.log";

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$tls_name = $ARGV[0];
$cert_file = $ARGV[1];
$key_file = $ARGV[2];

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

# Add secret-tls into K8s default namespace
$cmd = "$cmd_kubectl create secret tls $tls_name --cert=$cert_file --key=$key_file";
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