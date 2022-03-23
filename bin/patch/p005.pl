#!/usr/bin/perl
# 10:31 2022/3/23
# gitlab DNS mod / Redmine SECRET_KEY_BASE / SonarQube Liveness / Redis Store
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../../env.pl";
if (!-e $p_config) {
	print("Error! The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	print("Error! You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$cmd =<<END;
$Bin/../../gitlab/install_gitlab.pl dns_set;
$Bin/../../gitlab/install_gitlab.pl modify_ingress;
END
system($cmd);

# Check redmine SECRET_KEY_BASE setting
$cmd = "kubectl describe deployment redmine | grep REDMINE_SECRET_KEY_BASE";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg eq '') {
	$cmd = "$Bin/../../redmine/install_redmine.pl force";
	system($cmd);
}
else {
	print("The redmine SECRET_KEY_BASE setting already exists! Skip patch!\n");
}

# Check sonarqube-server Liveness setting
$cmd = "kubectl describe deployment sonarqube-server | grep Liveness";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg eq '') {
	$cmd = "$Bin/../../sonarqube/install_sonarqube.pl force";
	system($cmd);
}
else {
	print("The sonarqube-server liveness setting already exists! Skip patch!\n");
}

# Check devops-redis dir
if (!-e "$nfs_dir/devops-redis/") {
	$cmd = "kubectl apply -f $Bin/../../devops-redis";
	system($cmd);
}
else {
	print("The redis storage directory already exists! Skip patch!\n");
}
