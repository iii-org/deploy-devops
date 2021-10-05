#!/usr/bin/perl
# Remove develop env K8s user namespace deployments
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/common_lib.pl");

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$g_uuid = (!defined($ARGV[0]))?'no_uuid':$ARGV[0];

# iiidevops
$deploy_ver = get_nexus_info('deploy_version');
$deploy_uuid = get_nexus_info('deployment_uuid');
#print("[$deploy_ver][$deploy_uuid][$iiidevops_ver]\n");

if ($deploy_ver ne 'develop' && $deploy_uuid ne $g_uuid) {
	print("$prgname can only be executed in develop or specified UUID environment!\n");
	exit;
}

# Get user namespace 
$skip_ns = ',account,iiidevops-env-secret,cattle-global-data,cattle-global-nt,cattle-pipeline,cattle-system,cert-manager,ingress-nginx,kube-node-lease,kube-public,kube-system,default,';
# p-776j8-pipeline -> p-*-pipeline
$cmd_msg = `kubectl get namespace 2>&1`;
foreach $line (split("\n", $cmd_msg)) {
	$line =~ s/( )+/ /g;
	#print("[$line]..");
	if ($line eq 'NAME STATUS AGE') {
		#print("Skip\n");
		next;
	}
	($ns, $status, $age) = split(' ', $line);
	if (index($skip_ns, ",$ns,")>=0) {
		print("[$ns]..Skip\n");
		next;
	}
	print("[$ns]..Process..\n");
}