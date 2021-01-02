#!/usr/bin/perl
# remote add Kubernetes worker node script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
if (!defined($ARGV[0])) {
	print("Usage: $prgname user\@remote_ip\n");
	exit;
}

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$p_addk8s_sh = "$nfs_dir/deploy-config/add_k8s.sh";
if (!-e $p_addk8s_sh) {
	log_print("The addk8s_sh file [$p_config] does not exist!\n");
	exit;
}

$rancher_chk = "https://$rancher_ip:6443";
$addk8s_cmd = `cat $p_addk8s_sh`;
if (index($addk8s_cmd, $rancher_chk)<0) {
	log_print("The addk8s_sh file [$p_config] may be wrong! [$rancher_chk] is not exist!\n");
	exit;
}

# copy iiidevops_install.pl, add_k8s_node_sh to remote k8s node
$cmd = "scp $Bin/iiidevops_install.pl $p_addk8s_sh $ARGV[0]:~";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("\n");

# run and get remote k8s node info
$cmd = "ssh $ARGV[0] \"chmod a+x ~/add_k8s.sh; sudo -S perl ~/iiidevops_install.pl local; sudo -S ~/add_k8s.sh\"";
log_print("-----\n$cmd\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n\n");

$p_kube_config = "$nfs_dir/kube-config/config";
if (!-e $p_kube_config) {
	log_print("Please goto Rancher Web - $rancher_chk to get the status of added node of k8s cluster!\n");
	exit;
}

#kubectl get node
#NAME          STATUS   ROLES                      AGE   VERSION
#pve-devops2   Ready    controlplane,etcd,worker   53m   v1.18.12
$cmd = "kubectl get node";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");


exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}