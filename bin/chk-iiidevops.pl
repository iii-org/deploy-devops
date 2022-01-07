#!/usr/bin/perl
# Check iiidevops script
#
use FindBin qw($Bin);
use MIME::Base64;
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
log_print(`TZ='Asia/Taipei' date`);
log_print("----------------------------------------\n");


# Check kubernetes status.

log_print("1. Check kubernetes status..");
if (!get_service_status('kubernetes')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check if Gitlab/Rancher/Harbor/Redmine services are running well
# Check GitLab service is working
log_print("2. Check GitLab status..");
if (!get_service_status('gitlab')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}
	
# Check token-key 
#curl --silent --location --request GET 'http://10.50.1.53/api/v4/users' \
#--header 'PRIVATE-TOKEN: 7ZWkyr8PYwLyCvncKHwP'
# OK -> ,"username":
# Error -> {"message":"
log_print("3. Check GitLab TOKEN status..");
$chk_key = ',"username":';
$cmd_msg = call_gitlab_api('GET', 'users');
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Rancher service is working
log_print("4. Check Rancher status..");
if (!get_service_status('rancher')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Harbor service is working
log_print("5. Check Harbor status..");
if (!get_service_status('harbor')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Redmine service is working
log_print("6. Check Redmine status..");
if (!get_service_status('redmine')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Sonarqube service is working
log_print("6. Check Sonarqube status..");
if (!get_service_status('sonarqube')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

log_print("7. Check III DevOps status..");
# check iiidevops-api ready
if (!get_service_status('iiidevops')) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

log_print("----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
