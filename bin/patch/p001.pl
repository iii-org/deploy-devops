#!/usr/bin/perl
#15:15 2021/6/18
#Redmine File path Bug Patch:

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$cmd =<<END;
cd ~
sudo mkdir -p /iiidevopsNFS/redmine-files;
sudo chmod 777 /iiidevopsNFS/redmine-files;
./deploy-devops/redmine/install_redmine.pl force
END

system($cmd);
