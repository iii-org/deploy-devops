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

# NFS
if ($first_ip eq $nfs_ip) {
	$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
	system($cmd);
}
else {
	log_print("Skip NFS configuration!\n");
}

# Add insecure-registries
if ($harbor_ip ne '') {
	system("sudo $Bin/add-insecure-registries.pl $harbor_ip $harbor_domain_name");
}

# Install K8s
$cmd = "$Bin/../kubernetes/install_k8s.pl";
system($cmd);

# Install all devops components
if ($is_inscpnt ne 'base') {
	$cmd = "$Bin/iiidevops_install_cpnt.pl";
	system($cmd);
}
else {
	log_print("Skip install all devops components!\n");
}

exit;