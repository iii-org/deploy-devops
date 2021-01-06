#!/usr/bin/perl
# Install nfs service script
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
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

log_print("Install NFS : $nfs_ip - $nfs_dir\n");
# Check NFS is working
$cmd_msg = `showmount -e $nfs_ip 2>&1`;
$isWorking = index($cmd_msg, $nfs_dir)<0?0:1;
if ($isWorking) {
	log_print("NFS is running, I skip the installation!\n\n");
	exit;
}

$cmd = "sudo apt install nfs-kernel-server -y";
log_print("Install NFS service Package..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd_msg = `sudo cat /etc/exports`;
if (index($cmd_msg, $nfs_dir)<0) {
	$cmd = "echo '$nfs_dir *(no_root_squash,rw,sync,no_subtree_check)' |sudo tee -a /etc/exports";
	log_print("-----\n$cmd\n");
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n-----\n");
}

$cmd =<<END;
sudo mkdir -p $nfs_dir;
sudo chmod 777 $nfs_dir;
sudo systemctl restart nfs-kernel-server;
END
log_print("Setting & Restart NFS Service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

# Create folder for other services  
$cmd =<<END;
sudo mkdir -p $nfs_dir/redmine-postgresql;
sudo chmod 777 $nfs_dir/redmine-postgresql;
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
log_print("Create iiidevops services folder for NFS service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd_touch =<<END;
touch $nfs_dir/deploy-config/env.pl;
touch $nfs_dir/deploy-config/env.pl.ans;
END

$cmd_move =<<END;
mv $Bin/../env.pl $nfs_dir/deploy-config/;
mv $Bin/../env.pl.ans $nfs_dir/deploy-config/;
END

$cmd_link =<<END;
ln -s $nfs_dir/deploy-config/env.pl $Bin/../env.pl;
ln -s $nfs_dir/deploy-config/env.pl.ans $Bin/../env.pl.ans;
END

# copy env.pl.ans / env.pl to deploy-config/
if (!-e "$Bin/../env.pl") {
	$cmd_msg = `$cmd_touch`;
}
else {
	$cmd_msg = `$cmd_move`;
}
$cmd_msg .= `$cmd_link`;
if ($cmd_msg ne '') {
	log_print("Move env.pl to $nfs_dir/deploy-config/ ERROR!\n----\n$cmd_msg\n");
}
else {
	log_print("Move env.pl to $nfs_dir/deploy-config/ OK!\n");
}

# Check NFS service is working
$cmd = "showmount -e $nfs_ip";
#/iiidevopsNFS *
$chk_key = $nfs_dir;
$isChk=1;
$count=0;
$wait_sec=60;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("-----\n$cmd_msg-----\n");
if ($isChk) {
	log_print("NFS configuration failed!\n");
	exit;
}
log_print("NFS configuration OK!\n");
exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}