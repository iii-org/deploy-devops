#!/usr/bin/perl
# redeploy core script
#
$prgname = substr($0, rindex($0,"/")+1);
$kubeconf_str = defined($ARGV[0])?'--kubeconfig '.$ARGV[0]:'';

print("\n----------------------------------------\n");
print(`TZ='Asia/Taipei' date`);

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $$cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("[$cmd_kubectl] is not exist!!!\n");
	exit;
}


$cmd = "$cmd_kubectl $kubeconf_str rollout restart deployment devopsapi";
print("Redeploy devops-api..[$cmd]\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");


$cmd = "$cmd_kubectl $kubeconf_str rollout restart deployment devopsui";
print("Redeploy devops-ui..[$cmd]\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");
