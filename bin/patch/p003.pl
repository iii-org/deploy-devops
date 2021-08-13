#!/usr/bin/perl
# update to V1.7.1 ISO Patch:

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$cmd =<<END;
cd ~
./deploy-devops/bin/generate_env.pl iiidevops_ver 1.7.1 -y;
./deploy-devops/bin/iiidevops_install_core.pl;
./deploy-devops/bin/sync_chart_index.pl gitlab_update
END

system($cmd);