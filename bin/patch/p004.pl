#!/usr/bin/perl
# 15:46 2022/03/29
# Provide project default NFS path Patch / devops-redis NFS path Patch / websocket setting patch
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
	exit(1);
}

if (!defined($nfs_dir) || $nfs_dir eq '') {
	print("Error! The NFS directory is not defined!\n");
	exit(1);
}

if (-e "$nfs_dir/devops-data") {
	print("OK! The NFS directory [devops-data] have been defined!\n");
}

if (-e "$nfs_dir/devops-redis") {
	print("OK! The NFS directory [devops-redis] have been defined!\n");
}

# Check API & UI Service websocket mult pod setting
$cmd = "kubectl get svc devopsapi-service devopsui-service -o yaml | grep \"sessionAffinity: ClientIP\"";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne '') {
	print("OK! The API & UI websocket setting already exists! Skip patch!\n");
	exit;
}

$cmd =<<END;
$Bin/../iiidevops_install_core.pl
END

system($cmd);
