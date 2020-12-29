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
log_print("Install NFS service Package..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd_msg = `sudo cat /etc/exports`;
if (index($cmd_msg, $home_dir)<0) {
	$cmd = "echo '$home_dir *(no_root_squash,rw,sync,no_subtree_check)' |sudo tee -a /etc/exports";
	log_print("-----\n$cmd\n");
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n-----\n");
}

$cmd =<<END;
sudo mkdir $home_dir;
sudo chmod 777 $home_dir;
sudo systemctl restart nfs-kernel-server;
sudo showmount -e localhost;
END
log_print("Setting & Restart NFS Service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

# Create folder for other services  
$cmd =<<END;
sudo mkdir $home_dir/redmine-postgresql;
sudo chmod 777 $home_dir/redmine-postgresql;
sudo mkdir $home_dir/devopsdb;
sudo chmod 777 $home_dir/devopsdb;
sudo mkdir $home_dir/kube-config;
sudo chmod 777 $home_dir/kube-config;
sudo mkdir $home_dir/deploy-config;
sudo chmod 777 $home_dir/deploy-config;
sudo mkdir $home_dir/api-logs;
sudo chmod 777 $home_dir/api-logs;
sudo mkdir $home_dir/sonarqube;
sudo chmod 777 $home_dir/sonarqube;
END
log_print("Create iiidevops services folder for NFS service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd_touch =<<END;
touch $home_dir/deploy-config/env.pl;
touch $home_dir/deploy-config/env.pl.ans;
END

$cmd_move =<<END;
mv $Bin/../env.pl $home_dir/deploy-config/;
mv $Bin/../env.pl.ans $home_dir/deploy-config/;
END

$cmd_link =<<END;
ln -s $home_dir/deploy-config/env.pl $Bin/../env.pl;
ln -s $home_dir/deploy-config/env.pl.ans $Bin/../env.pl.ans;
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
	log_print("Move env.pl to $home_dir/deploy-config/ ERROR!\n----\n$cmd_msg\n");
}
else {
	log_print("Move env.pl to $home_dir/deploy-config/ OK!\n");
}

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}