#!/usr/bin/perl
# Install iiidevops base applications script
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
$logfile = "$Bin/$prgname.log";
$is_inscpnt = defined($ARGV[0])?lc($ARGV[0]):''; # 'base' : skip install iiidevops_cpnt

require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

# Create NFS Dir & Services Data Dir
if ($nfs_dir eq '') {
	log_print("The nfs_dir is not setting!\n");
	exit;
}
else {
	$cmd =<<END;
sudo mkdir -p $nfs_dir;
sudo chmod 777 $nfs_dir;
sudo mkdir -p $nfs_dir/pvc;
sudo chmod 777 $nfs_dir/pvc;
sudo mkdir -p $nfs_dir/gitlab/config;
sudo mkdir -p $nfs_dir/gitlab/data;
sudo mkdir -p $nfs_dir/gitlab/logs;
sudo chmod -R 777 $nfs_dir/gitlab;
sudo mkdir -p $nfs_dir/redmine-postgresql;
sudo chmod 777 $nfs_dir/redmine-postgresql;
sudo mkdir -p $nfs_dir/redmine-files;
sudo chmod 777 $nfs_dir/redmine-files;
sudo mkdir -p $nfs_dir/devopsdb;
sudo chmod 777 $nfs_dir/devopsdb;
sudo mkdir -p $nfs_dir/kube-config;
sudo chmod 777 $nfs_dir/kube-config;
sudo mkdir -p $nfs_dir/deploy-config;
sudo chmod 777 $nfs_dir/deploy-config;
sudo mkdir -p $nfs_dir/api-logs;
sudo chmod 777 $nfs_dir/api-logs;
sudo mkdir -p $nfs_dir/sonarqube-postgresql;
sudo chmod 777 $nfs_dir/sonarqube-postgresql;
END
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("Create nfs directory [$nfs_dir] failed!\n$cmd_msg\n-----\n");
		exit;
	}
	log_print("Create nfs directory OK!\n");
}

# copy env.pl.ans / env.pl / env.conf to deploy-config/
#if (length(`dpkg -l | grep "ii  iiidevops "`)>0) {
#}
# If /iiidevopsNFS/deploy-config/env.pl exists, the file link is automatically created
#$nfs_dir = '/iiidevopsNFS';
#$p_config = "$Bin/deploy-devops/env.pl";
$cmd_msg = '';
$n_config = "$nfs_dir/deploy-config/env.pl";
$t_config = "$Bin/../env.pl";
if (-e $n_config) {
	$cmd_msg .= `rm $t_config;ln -s $n_config $t_config`; 
	log_print("$t_config file link is automatically created ..OK!\n");
}
elsif (-e $t_config) {
	$cmd_msg .= `mv $t_config $n_config; ln -s $n_config $t_config`; 
}

$n_config = "$nfs_dir/deploy-config/env.pl.ans";
$t_config = "$Bin/../env.pl.ans";
if (-e $n_config) {
	$cmd_msg .= `rm $t_config;ln -s $n_config $t_config`; 
	log_print("$t_config file link is automatically created ..OK!\n");
}
elsif (-e $t_config) {
	$cmd_msg .= `mv $t_config $n_config; ln -s $n_config $t_config`; 
}

$n_config = "$nfs_dir/deploy-config/env.conf";
$t_config = "$Bin/../env.conf";
if (-e $n_config) {
	$cmd_msg .= `rm $t_config;ln -s $n_config $t_config`; 
	log_print("$t_config file link is automatically created ..OK!\n");
}
elsif (-e $t_config) {
	$cmd_msg .= `mv $t_config $n_config; ln -s $n_config $t_config`; 
}

if ($cmd_msg ne '') {
	log_print("Move env.pl to $nfs_dir/deploy-config/ ERROR!\n----\n$cmd_msg\n");
}
else {
	log_print("Move env.pl to $nfs_dir/deploy-config/ OK!\n");
}

# Gen K8s ssh key
if (-e "$nfs_dir/deploy-config/id_rsa") {
	$cmd = "mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
else {
	$cmd = "sudo -u rkeuser ssh-keygen -t rsa -C '$admin_init_email' -f $nfs_dir/deploy-config/id_rsa -q -N '';mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
}
system($cmd);

# Trust first node & Check rkeuser permission
$cmd ="cp $nfs_dir/deploy-config/id_rsa.pub /home/rkeuser/.ssh/authorized_keys; chmod 600 /home/rkeuser/.ssh/authorized_keys;ssh -o StrictHostKeychecking=no $first_ip \"docker ps\"";
$cmd_msg = `$cmd 2>&1`;
$chk_key = 'CREATED';
#CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
if (index($cmd_msg, $chk_key)<0) {
	log_print("Verify rkeuser permission for running docker failed!\n");
	exit;
}
log_print("Verify rkeuser permission for running docker OK!\n");

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

# Install K8s
system("$Bin/../kubernetes/update-k8s-setting.pl Initial $first_ip");
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
if ($is_inscpnt ne 'base') {
	$cmd = "$Bin/iiidevops_install_cpnt.pl";
	system($cmd);
}
else {
	log_print("Skip install all devops components!\n");
}

exit;