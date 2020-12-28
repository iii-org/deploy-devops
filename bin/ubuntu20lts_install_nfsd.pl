#!/usr/bin/perl
# Install nfs service script
#
use FindBin qw($Bin);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$home_dir = "/iiidevopsNFS";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$cmd = "sudo apt install nfs-kernel-server -y";
print("Install NFS service Package..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd_msg = `sudo cat /etc/exports`;
if (index($cmd_msg, $home_dir)<0) {
	$cmd = "echo '$home_dir *(no_root_squash,rw,sync,no_subtree_check)' |sudo tee -a /etc/exports";
	log_print("-----\n$cmd\n");
	$cmd_msg = `$cmd`;
	print("-----\n$cmd_msg\n-----\n");
}

$cmd =<<END;
sudo mkdir $home_dir;
sudo chmod 777 $home_dir;
sudo systemctl restart nfs-kernel-server;
sudo showmount -e localhost;
END
print("Setting & Restart NFS Service..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

# Create folder for other services  
$cmd =<<END;
sudo mkdir $home_dir/redmine-postgresql;
sudo chmod 777 $home_dir/redmine-postgresql;
sudo mkdir $home_dir/devopsdb;
sudo chmod 777 $home_dir/devopsdb;
sudo mkdir $home_dir/kube-config;
sudo chmod 777 $home_dir/kube-config;
sudo mkdir $home_dir/api-logs;
sudo chmod 777 $home_dir/api-logs;
sudo mkdir $home_dir/sonarqube;
sudo chmod 777 $home_dir/sonarqube;
END
print("Create iiidevops services folder for NFS service..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}