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
$white_list_file = $nfs_dir.'/deploy-config/rm-dev-deployment.whitelist';

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

$kubeconf_str = defined($ARGV[1])?'--kubeconfig '.$ARGV[1]:'--kubeconfig /home/rkeuser/.kube/config';
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
 
# Get user namespace white list
$skip_user_ns ='';
if (-e $white_list_file) {
	$file_msg = `cat $white_list_file`;
	foreach $line (split("\n|\r", $file_msg)) {
		$line =~ s/ //g;
		if ($line ne '') {
			$skip_user_ns .= $line.' |';
		}
	}
}

# Delete user namespace deployment
$skip_ns = $skip_user_ns."account |iiidevops-env-secret |cattle-global-data |cattle-global-nt |cattle-pipeline |cattle-system |cert-manager |ingress-nginx |kube-node-lease |kube-public |kube-system |default |^p-";
$cmd_msg = `$cmd_kubectl get ns | egrep -v "$skip_ns" | grep -v "NAME " | awk '{print \$1}'`;
foreach $line (split("\n", $cmd_msg)) {
        print(`TZ='Asia/Taipei' date +%Y/%m/%d-%H:%M:%S`."Delete [$line] deployment at ...\n");
        $delete_cmd_msg = `$cmd_kubectl delete deployment --all -n $line`;
        print("$delete_cmd_msg\n");
}