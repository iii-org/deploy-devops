#!/usr/bin/perl
# Delete all k8s cronjob and restart api pod
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");

$kubeconf_str = defined($ARGV[0]) ? '--kubeconfig ' . $ARGV[0] : '';
$prgname = substr($0, rindex($0, "/") + 1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("[$cmd_kubectl] is not exist!!!\n");
	exit;
}
$kubectl = "$cmd_kubectl $kubeconf_str";

# kubectl get cronjobs -n default -o custom-columns=:.metadata.name
@default_cjs = split(/\s+/, `$kubectl get cronjobs -n default -o custom-columns=:.metadata.name`);

# For each cronjob, delete it
foreach $cj (@default_cjs) {
    if ($cj) {
        $cmd = `$kubectl delete cronjob $cj -n default`;
        log_print($cmd);
    }
}

# Restart api pod
$cmd = `$kubectl rollout restart deployment devopsapi`;
log_print("DevOps API pod restarted!\n");
