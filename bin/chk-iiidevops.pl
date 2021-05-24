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
$cmd = "kubectl get pod | grep redmine | tail -1";
log_print("1. Check kubernetes status..");
$cmd_msg = `$cmd`;
if (index($cmd_msg, 'Running')<0) {
	log_print("The Kubernetes cluster is not working properly!\n");
}
else {
	log_print("OK!\n");
}

# Check if Gitlab/Rancher/Harbor/Redmine services are running well
# Check GitLab service is working
log_print("2. Check GitLab status..");
$gitlab_domain_name = get_domain_name('gitlab');
$cmd = "curl -q -I http://$gitlab_domain_name/users/sign_in";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
#HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
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
$cmd = "curl --silent --location --request GET 'http://$gitlab_domain_name/api/v4/users' --header 'PRIVATE-TOKEN: $gitlab_private_token'";
$chk_key = ',"username":';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Rancher service is working
log_print("4. Check Rancher status..");
$cmd = "nc -z -v $rancher_ip 3443";
$chk_key = 'succeeded!';
$cmd_msg = `$cmd 2>&1`;
# Connection to 10.20.0.71 3443 port [tcp/*] succeeded!
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Harbor service is working
log_print("5. Check Harbor status..");
$harbor_domain_name = get_domain_name('harbor');
$cmd = "curl -k --location --request POST 'https://$harbor_domain_name/api/v2.0/registries'";
$chk_key = 'UNAUTHORIZED';
$cmd_msg = `$cmd 2>&1`;
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Redmine service is working
log_print("6. Check Redmine status..");
$redmine_domain_name = get_domain_name('redmine');
$cmd = "curl -q -I http://$redmine_domain_name";
$chk_key = '200 OK';
$cmd_msg = `$cmd 2>&1`;
# HTTP/1.1 200 OK
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

# Check Sonarqube service is working
log_print("6. Check Sonarqube status..");
$sonarqube_domain_name = get_domain_name('sonarqube');
$cmd = "curl -q -I http://$sonarqube_domain_name";
$chk_key = 'Content-Type: text/html;charset=utf-8';
$cmd_msg = `$cmd 2>&1`;
# Content-Type: text/html;charset=utf-8
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

log_print("7. Check DevOps-DB..");
# Check the database is ready!
$cmd_msg = `nc -z -v $db_ip 31403 2>&1`;
# Connection to 192.168.11.205 31403 port [tcp/*] succeeded!
$chk_key = 'succeeded!';
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

log_print("8. Check III DevOps-AP..");
# check iiidevops-api ready
$cmd = "curl -s --location --request POST '$iiidevops_api/user/login'";
#{ "message": {
#        "username": "Missing required parameter in the JSON body or the post body or the query string" }}
$cmd_msg = `$cmd`;
$chk_key = 'username';
if (index($cmd_msg, $chk_key)<0) {
	log_print("not working!\n");
}
else {
	log_print("OK!\n");
}

log_print("----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

log_print("\nIII-DevOps - http://$iiidevops_domain_name\n\n");
