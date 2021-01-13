#!/usr/bin/perl
# Install iiidevops applications on kubernetes cluster script
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
$home = "$Bin/../../";

# Redmine
$cmd = "$home/deploy-devops/redmine/install_redmine.pl";
log_print("Deploy Redmine..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check Redmine service is working
$redmine_domain_name = ($redmine_domain_name eq '')?"redmine.iiidevops.$redmine_ip.xip.io":$redmine_domain_name;
$cmd = "curl -q -I http://$redmine_domain_name";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
# HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Redmine!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Redmine..OK!\n\n");

# Sonarqube
$cmd = "$home/deploy-devops/sonarqube/install_sonarqube.pl";
log_print("Deploy Sonarqube..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check Sonarqube service is working
$sonarqube_domain_name = ($sonarqube_domain_name eq '')?"sonarqube.iiidevops.$sonarqube_ip.xip.io":$sonarqube_domain_name;
$cmd = "curl -q -I http://$sonarqube_domain_name";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
# HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Sonarqube!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Sonarqube ..OK!\n\n");

log_print("The deployment of Redmine & other services has been completed, These services URL are: \n");
log_print("Redmine - http://$redmine_ip:32748/\n");
log_print("Sonarqube - http://$sonarqube_ip:31910/\n");
log_print("\nPlease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 7. to continue.\n\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}