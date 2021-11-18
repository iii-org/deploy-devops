#!/usr/bin/perl
# 18:09 2021/11/18
# Provide project default NFS path Patch:
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

$cmd =<<END;
cd ~
sudo mkdir -p $nfs_dir/project-data;
sudo chmod 777 $nfs_dir/project-data;
./deploy-devops/bin/iiidevops_install_core.pl
END

system($cmd);
