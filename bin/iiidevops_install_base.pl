#!/usr/bin/perl
# Install iiidevops base applications script
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
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

# Create Data Dir
$cmd = "sudo mkdir -p $data_dir";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne '') {
	log_print("Create data directory [$data_dir] failed!\n$cmd_msg\n-----\n");
	exit;
}
log_print("Create data directory OK!\n");

# NFS
if ($first_ip eq $nfs_ip) {
	$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
	log_print("\nInstall & Setting NFS service..");
	system($cmd);
	# Check NFS service is working
	$cmd = "showmount -e $nfs_ip";
	$chk_key = $nfs_dir;
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg-----\n");
	if (index($cmd_msg, $chk_key)<0) {
		log_print("NFS configuration failed!\n");
		exit;
	}
	log_print("NFS configuration OK!\n");
}
else {
	log_print("Skip NFS configuration!\n");
}

# Add insecure-registries
if ($harbor_ip ne '') {
	system("sudo $Bin/add-insecure-registries.pl $harbor_ip $harbor_domain_name");
}

# Gen K8s ssh key
if (-e "$nfs_dir/deploy-config/id_rsa") {
	$cmd = "mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
else {
	$cmd = "sudo -u rkeuser ssh-keygen -t rsa -C '$admin_init_email' -f $nfs_dir/deploy-config/id_rsa -q -N '';mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
system($cmd);

# Copy ssh key to first_ip
$cmd = "ssh-copy-id -i $nfs_dir/deploy-config/id_rsa.pub rkeuser\@$first_ip";
system($cmd);
# Verify rkeuser permission for running docker 
$cmd = "ssh rkeuser\@$first_ip -C 'docker ps'";
$chk_key = 'CREATED';
$cmd_msg = `$cmd 2>&1`;
#CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
if (index($cmd_msg, $chk_key)<0) {
	log_print("Verify rkeuser permission for running docker failed!\n");
	exit;
}
log_print("Verify rkeuser permission for running docker OK!\n");

# Install K8s
system("$Bin/../kubernetes/update-k8s-cluster.pl Initial $first_ip");
system("sudo -u rkeuser rke up --config $nfs_dir/deploy-config/cluster.yml");

$cmd = "cp -a $nfs_dir/deploy-config/kube_config_cluster.yml $nfs_dir/kube-config/config; ln -f -s $nfs_dir/kube-config/config ~rkeuser/.kube/config";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne '') {
	log_print("Copy kubeconf failed!..\n$cmd_msg\n");
	exit;
}

# Verify kubeconf & Check kubernetes status.
log_print("Verify kubeconf & Check kubernetes status..\n");
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('kubernetes'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy K8s!\n");
	exit;
}
log_print("Successfully deployed K8s!\n");
 
# Create Namespace on kubernetes cluster
$cmd = "kubectl apply -f $Bin/../kubernetes/namespaces/account.yaml";
log_print("Create Namespace on kubernetes cluster..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");
if (index($cmd_msg, 'namespace/account created')<0 && index($cmd_msg, 'namespace/account unchanged')<0) {
	log_print("Failed to create namespace on kubernetes cluster!\n");
	exit;
}
log_print("Create namespace on kubernetes cluster OK!\n");

# Install all devops components 
$cmd = "$Bin/iiidevops_install_cpnt.pl";
system($cmd);

exit;