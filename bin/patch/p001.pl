#!/usr/bin/perl
# 15:15 2021/6/18
# Redmine File path Bug Patch:
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

if (!defined($nfs_dir) || $nfs_dir eq '') {
	print("Error! The NFS directory is not defined!\n");
	exit;
}

if (-e "$nfs_dir/redmine-files") {
	print("OK! The NFS directory [redmine-files] has been defined!\n");
	exit;
}

$cmd =<<END;
mkdir -p $nfs_dir/redmine-files;
chmod 777 $nfs_dir/redmine-files;
$Bin/../../redmine/install_redmine.pl force
END

system($cmd);
