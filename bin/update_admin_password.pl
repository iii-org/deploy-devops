#!/usr/bin/perl
# Update IIIDevOps Admin Password
#
use FindBin qw($Bin);
use MIME::Base64;
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit(1);
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$change_passwd = defined($ARGV[0])?$ARGV[0]:''; # Change IIIdevops service admin password
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check change_passwd
$regex = qr/(?=.*\d)(?=.*[a-z])(?=.*[A-Z])^[\w!@#$%^&*()+|{}\[\]`~\-\'\";:\/?.\\>,<]{8,20}$/mp;  # Check password rule
if ($change_passwd eq '') {
	print("The password does not set!\n");
	exit(1);
}
elsif (!($change_passwd =~ /$regex/g) ){ 
	print("$change_passwd - Password is irregular!\nPassword should be 8-20 characters long with at least 1 uppercase, 1 lowercase and 1 number!\n");
	exit(1);
}

# Check kubernetes status.
log_print("Check kubernetes status..\n");
if (!get_service_status('kubernetes')) {
	log_print("The Kubernetes cluster is not working properly!\n");
	exit(1);
}
log_print("Kubernetes cluster is working well!\n");

# Check GitLab service is working
if (!get_service_status('gitlab')) {
	log_print("GitLab is not working!\n");
	exit(1);
}
$chk_key = ',"username":';
$cmd_msg = call_gitlab_api('GET', 'users');
if (index($cmd_msg, $chk_key)<0) {
	log_print("GitLab private-token is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit(1);	
}
log_print("GitLab is working well!\n");

# Set allow_local_requests_from_web_hooks_and_services
$chk_key = '"allow_local_requests_from_web_hooks_and_services":true';
$cmd_msg = call_gitlab_api('PUT', 'application/settings?allow_local_requests_from_web_hooks_and_services=true');
if (index($cmd_msg, $chk_key)<0) {
	log_print("Set GitLab allow_local_requests_from_web_hooks_and_services failed!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit(1);	
}
log_print("Set GitLab allow_local_requests_from_web_hooks_and_services = true!\n");

# Set signup_enabled
$chk_key = '"signup_enabled":false';
$cmd_msg = call_gitlab_api('PUT', 'application/settings?signup_enabled=false');
if (index($cmd_msg, $chk_key)<0) {
	log_print("Set GitLab signup_enabled failed!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit(1);	
}
log_print("Set GitLab signup_enabled = false!\n");

# Check Rancher service is working
if (!get_service_status('rancher')) {
	log_print("Rancher is not working!\n");
	exit(1);
}
log_print("Rancher is working well!\n");

# Check Harbor service is working
if (!get_service_status('harbor')) {
	log_print("Harbor is not working!\n");
	exit(1);
}
$harbor_domain_name = get_domain_name('harbor');
log_print("Harbor is working well!\n");

# Check Redmine service is working
if (!get_service_status('redmine')) {
	log_print("Redmine is not working!\n");
	exit(1);
}
log_print("Redmine is working well!\n");

# Check Sonarqube service is working
if (!get_service_status('sonarqube')) {
	log_print("Sonarqube is not working!\n");
	exit(1);
}
# Check token-key
#curl -u 72110dbe6fb0f621657204b9db1594cf3bd805a1: --request GET 'http://10.20.0.35:31910/api/authentication/validate'
#{"valid":true}
$chk_key = '{"valid":true}';
$cmd_msg = call_sonarqube_api('GET', 'authentication/validate');
if (index($cmd_msg, $chk_key)<0) {
	log_print("Sonarqube admin-token is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit(1);
}
log_print("Sonarqube is working well!\n");


# Change IIIDevOps Administrator Password
$iiidevops_chk = update_admin_password($change_passwd);
sleep(5);
if (!$iiidevops_chk) {
	print("Change IIIDevOps administrators password fail!\n");
	exit(1);
}else{
	print("\nChange IIIDevOps administrators password success!\n");
	print("modify env.pl admin_init_password:\n");
	system("perl $Bin/generate_env.pl admin_init_password $change_passwd -y");
}

# Change Gitlab Administrator Password
if (!update_gitlab_user_password("root",$change_passwd)) {
	print("Change Gitlab administrators password fail!\n");
	exit(1);
}
else{
	print("\nChange Gitlab administrators password success!\n");
	print("modify env.pl Gitlab_root_password:\n");
	system("perl $Bin/generate_env.pl gitlab_root_password $change_passwd -y");
}

# Change Redmine Administrator Password
if (!update_redmine_user_password("admin",$change_passwd)) {
	print("Change Redmine administrators password fail!\n");
	exit(1);
}
else{
	print("\nChange Redmine administrators password success!\n");
	print("modify env.pl redmine_admin_password:\n");
	system("perl $Bin/generate_env.pl redmine_admin_password $change_passwd -y");
}

# Change Sonarqube Administrator Password
if (!update_sonarqube_user_password("admin",$change_passwd,$sonarqube_admin_passwd)) {
	print("Change Sonarqube administrators password fail!\n");
	exit(1);
}
else{
	print("\nChange Sonarqube administrators password success!\n");
	print("modify env.pl sonarqube_admin_passwd:\n");
	system("perl $Bin/generate_env.pl sonarqube_admin_passwd $change_passwd -y");
}

# Change Harbor Administrator Password
if (!update_harbor_user_password("admin",$change_passwd,$harbor_admin_password) ) {
	print("Change Harbor administrators password fail!\n");
	exit(1);
}else{
	print("\nChange Harbor administrators password success!\n");
	print("modify env.pl harbor_admin_password:\n");
	system("perl $Bin/generate_env.pl harbor_admin_password $change_passwd -y");
}

# Change rancher Administrator Password
if (!update_rancher_user_password("admin",$change_passwd,$rancher_admin_password)) {
	print("Change Rancher administrators password fail!\n");
	exit(1);
}else{
	print("\nChange Rancher administrators password success!\n");
	print("modify env.pl rancher_admin_password:\n");
	system("perl $Bin/generate_env.pl rancher_admin_password $change_passwd -y");
}

system("$Bin/iiidevops_install_core.pl");