#!/usr/bin/perl
# 17:27 2021/12/29
# gitlab DNS mod 
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
$Bin/../../redmine/install_redmine.pl force
kubectl apply -f $Bin/../../devops-redis
END

system($cmd);
