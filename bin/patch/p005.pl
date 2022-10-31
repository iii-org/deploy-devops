#!/usr/bin/perl
# 10:31 2022/10/31
# gitlab DNS mod / Redmine SECRET_KEY_BASE && proxy-body-size 100m / SonarQube Liveness / Redis Store
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../../env.pl";
if (!-e $p_config) {
	print("Error! The configuration file [$p_config] does not exist!\n");
	exit(1);
}
require($p_config);
require("$Bin/../../lib/iiidevops_lib.pl");

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	print("Error! You must use the 'rkeuser' account to run the installation script!\n");
	exit(1);
}

$error_count=0;

# Check redmine SECRET_KEY_BASE setting
$patch_redmine=0;
$cmd = "kubectl describe deployment redmine | grep REDMINE_SECRET_KEY_BASE";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg eq '') {
	$patch_redmine++;
}
else {
	print("The redmine SECRET_KEY_BASE setting already exists! Skip patch!\n");
}

# Check redmine proxy-body-size setting
$cmd = "kubectl describe ingress redmine-ing | grep proxy-body-size";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg eq '') {
	$patch_redmine++;
}
else {
	print("The redmine proxy-body-size setting already exists! Skip patch!\n");
}

# Run Redmine Patch
if ($patch_redmine) {
	$cmd = "$Bin/../../redmine/install_redmine.pl force";
	$error_count += system($cmd) >> 8;
}

# Check sonarqube-server Liveness setting
$cmd = "kubectl describe deployment sonarqube-server | grep Liveness";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg eq '') {
	$cmd = "$Bin/../../sonarqube/install_sonarqube.pl force";
	$error_count += system($cmd) >> 8;
}
else {
	print("The sonarqube-server liveness setting already exists! Skip patch!\n");
}

exit($error_count);