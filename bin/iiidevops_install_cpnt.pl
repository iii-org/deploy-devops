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
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";


# GitLab
$cmd = "$home/deploy-devops/gitlab/install_gitlab.pl";
log_print("\nDeploy Gitlab..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check GitLab service is working
$gitlab_domain_name = get_domain_name('gitlab');
$cmd = "curl -q -I http://$gitlab_domain_name/users/sign_in";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
# HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy GitLab!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Successfully deployed GitLab!\n");


# Redmine
$cmd = "$home/deploy-devops/redmine/install_redmine.pl";
log_print("Deploy Redmine..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check Redmine service is working
$redmine_domain_name = get_domain_name('redmine');
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

# Harbor
$cmd = "$home/deploy-devops/harbor/install_harbor.pl";
log_print("\nDeploy Harbor..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check Harbor service is working
$harbor_domain_name = get_domain_name('harbor');
$cmd = "curl -k --location --request POST 'https://$harbor_domain_name/api/v2.0/registries' 2>&1";
$chk_key = 'UNAUTHORIZED';
$cmd_msg = `$cmd 2>&1`;
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Harbor!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Successfully deployed Harbor!\n");

# Sonarqube
$cmd = "$home/deploy-devops/sonarqube/install_sonarqube.pl";
log_print("Deploy Sonarqube..");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");
# Check Sonarqube service is working
$sonarqube_domain_name = get_domain_name('sonarqube');
$cmd = "curl -q -I http://$sonarqube_domain_name";
$chk_key = 'Content-Type: text/html;charset=utf-8';
$cmd_msg = `$cmd 2>&1`;
# Content-Type: text/html;charset=utf-8
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Sonarqube!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Sonarqube ..OK!\n\n");

log_print("The deployment of these services has been completed. The service URLs are: \n");
log_print("GitLab - http://$gitlab_domain_name/\n");
log_print("Redmine - http://$redmine_domain_name/\n");
log_print("Harbor - https://$harbor_domain_name/\n");
log_print("Sonarqube - http://$sonarqube_domain_name/\n");
log_print("\nPlease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 7. to continue.\n\n");

exit;
