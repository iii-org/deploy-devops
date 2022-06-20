#!/usr/bin/perl
# redeploy core script
#
$prgname = substr($0, rindex($0,"/")+1);
$kubeconf_str = defined($ARGV[0])?'--kubeconfig '.$ARGV[0]:'';

print("\n----------------------------------------\n");
print(`TZ='Asia/Taipei' date`);

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("[$cmd_kubectl] is not exist!!!\n");
	exit;
}


$cmd = "$cmd_kubectl $kubeconf_str get node -o wide | awk 'NR!=1 {print \$6}'";
# print("Redeploy devops-api..[$cmd]\n");
$cmd_msg = `$cmd`;
foreach $node (split(/\n/, $cmd_msg)) {
	$restart_cmd =`ssh -o "StrictHostKeyChecking no" $node docker restart kubelet`;
	print("$node kubelet restart is ");
	if (index($restart_cmd, 'kubelet')>=0) {
		print("success\n");
	}
	else {
		print("fail\n");
	}
}