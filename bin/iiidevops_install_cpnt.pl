#!/usr/bin/perl
# Install iiidevops applications on kubernetes cluster script
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

# Rancher
$cmd = "$home/deploy-devops/rancher/install_rancher.pl";
log_print("\nDeploy Rancher..");
system($cmd);
# Check Rancher service is working
if (!get_service_status('rancher')) {
	log_print("Rancher is not working!\n");
	exit;
}
log_print("Rancher is working well!\n\n");

# Redmine
$cmd = "$home/deploy-devops/redmine/install_redmine.pl";
log_print("\nDeploy Redmine..");
system($cmd);
# Check Redmine service is working
if (!get_service_status('redmine')) {
	log_print("Redmine is not working!\n");
	exit;
}
log_print("Redmine is working well!\n\n");

# Harbor
$cmd = "$home/deploy-devops/harbor/install_harbor.pl";
log_print("\nDeploy Harbor..");
system($cmd);
# Check Harbor service is working
if (!get_service_status('harbor')) {
	log_print("Harbor is not working!\n");
	exit;
}
log_print("Harbor is working well!\n\n");

# Sonarqube
$cmd = "$home/deploy-devops/sonarqube/install_sonarqube.pl";
log_print("\nDeploy Sonarqube..");
system($cmd);
# Check Sonarqube service is working
if (!get_service_status('sonarqube')) {
	log_print("Sonarqube is not working!\n");
	exit;
}
log_print("Sonarqube is working well!\n\n");

# GitLab
$cmd = "$home/deploy-devops/gitlab/install_gitlab.pl";
log_print("\nDeploy Gitlab..");
system($cmd);
# Check GitLab service is working
if (!get_service_status('gitlab')) {
	log_print("GitLab is not working!\n");
	exit;
}
log_print("GitLab is working well!\n\n");

log_print("----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("The deployment of these services has been completed. The service URLs are: \n");
log_print("Rancher - https://".get_domain_name('rancher')."/\n");
log_print("GitLab - http://".get_domain_name('gitlab')."/\n");
log_print("Redmine - http://".get_domain_name('redmine')."/\n");
log_print("Harbor - https://".get_domain_name('harbor')."/\n");
log_print("Sonarqube - http://".get_domain_name('sonarqube')."/\n");
log_print("\nPlease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 4. to continue.\n\n");

exit;
