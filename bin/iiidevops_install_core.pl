#!/usr/bin/perl
# Install iiidevops core script
#
use FindBin qw($Bin);
use MIME::Base64;
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


# Check kubernetes status.
log_print("Check kubernetes status..\n");
if (!get_service_status('kubernetes')) {
	log_print("The Kubernetes cluster is not working properly!\n");
	exit;
}
log_print("Kubernetes cluster is working well!\n");

# Check GitLab service is working
if (!get_service_status('gitlab')) {
	log_print("GitLab is not working!\n");
	exit;
}
$gitlab_domain_name = get_domain_name('gitlab');
$gitlab_port = (uc($deploy_mode) ne 'IP')?80:32080;
# Check token-key 
#curl --silent --location --request GET 'http://10.50.1.53/api/v4/users' \
#--header 'PRIVATE-TOKEN: 7ZWkyr8PYwLyCvncKHwP'
# OK -> ,"username":
# Error -> {"message":"
$cmd = "curl --silent --location --request GET 'http://$gitlab_domain_name/api/v4/users' --header 'PRIVATE-TOKEN: $gitlab_private_token'";
$chk_key = ',"username":';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("GitLab private-token is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}

# Set allow_local_requests_from_web_hooks_and_services
#curl --request PUT --header "PRIVATE-TOKEN: 7ZWkyr8PYwLyCvncKHwP" http://10.50.1.53/api/v4/application/settings?allow_local_requests_from_web_hooks_and_services=true
# "allow_local_requests_from_web_hooks_and_services":true
$cmd = "curl --request PUT 'http://$gitlab_domain_name/api/v4/application/settings?allow_local_requests_from_web_hooks_and_services=true' --header 'PRIVATE-TOKEN: $gitlab_private_token'";
$chk_key = '"allow_local_requests_from_web_hooks_and_services":true';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("GitLab allow_local_requests_from_web_hooks_and_services is not true!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("GitLab is working well!\n");

# Check Rancher service is working
if (!get_service_status('rancher')) {
	log_print("Rancher is not working!\n");
	exit;
}
log_print("Rancher is working well!\n");

# Check Harbor service is working
if (!get_service_status('harbor')) {
	log_print("Harbor is not working!\n");
	exit;
}
$harbor_domain_name = get_domain_name('harbor');
log_print("Harbor is working well!\n");

# Check Redmine service is working
if (!get_service_status('redmine')) {
	log_print("Redmine is not working!\n");
	exit;
}
$redmine_domain_name = get_domain_name('redmine');
log_print("Redmine is working well!\n");

# Check Sonarqube service is working
if (!get_service_status('sonarqube')) {
	log_print("Sonarqube is not working!\n");
	exit;
}
$sonarqube_domain_name = get_domain_name('sonarqube');
# Check token-key
#curl -u 72110dbe6fb0f621657204b9db1594cf3bd805a1: --request GET 'http://10.20.0.35:31910/api/authentication/validate'
#{"valid":true}
$cmd = "curl -u $sonarqube_admin_token: --request GET 'http://$sonarqube_domain_name/api/authentication/validate'";
$chk_key = '{"valid":true}';
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_key)<0) {
	log_print("Sonarqube admin-token is not working!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("Sonarqube is working well!\n");

# Deploy DevOps DB (Postgresql) on kubernetes cluster
$yaml_path = "$Bin/../devops-db/";
$yaml_file = $yaml_path.'devopsdb-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-db..\n");
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n\n");

# Check the database is ready!
$isChk=1;
$cmd = "psql -d 'postgresql://postgres:$db_passwd\@$db_ip:31403' -c 'SELECT version();'";
# PostgreSQL 12.6 (Debian 12.6-1.pgdg100+1) on x86_64-pc-linux-gnu, compiled by gcc (Debian 8.3.0-6) 8.3.0, 64-bit
$chk_key = 'PostgreSQL';
while($isChk) {
	print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = index($cmd_msg, $chk_key)<0?3:0;
	sleep($isChk);
}
print("OK!\n");

# iiidevops_ver
$iiidevops_ver = ($iiidevops_ver eq '')?'1':$iiidevops_ver;

# Deploy DevOps API (Python Flask) on kubernetes cluster
$yaml_path = "$Bin/../devops-api/";
$yaml_file = $yaml_path.'devopsapi-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}

$template = `cat $tmpl_file`;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{db_ip}}/$db_ip/g;
$template =~ s/{{jwt_secret_key}}/$jwt_secret_key/g;
$template =~ s/{{redmine_domain_name}}/$redmine_domain_name/g;
$template =~ s/{{redmine_admin_passwd}}/$redmine_admin_passwd/g;
$template =~ s/{{redmine_api_key}}/$redmine_api_key/g;
$template =~ s/{{gitlab_port}}/$gitlab_port/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_ip}}/$rancher_ip/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{harbor_ip}}/$harbor_ip/g;
$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
$template =~ s/{{k8sctl_domain_name}}/$k8sctl_domain_name/g;
$template =~ s/{{ingress_domain_name}}/$ingress_domain_name/g;
$template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
$template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
$template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
$template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;
$template =~ s/{{webinspect_base_url}}/$webinspect_base_url/g;
$template =~ s/{{sonarqube_domain_name}}/$sonarqube_domain_name/g;
$template =~ s/{{sonarqube_admin_token}}/$sonarqube_admin_token/g;
$template =~ s/{{admin_init_login}}/$admin_init_login/g;
$template =~ s/{{admin_init_email}}/$admin_init_email/g;
$template =~ s/{{admin_init_password}}/$admin_init_password/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-api..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");


# Deploy DevOps UI (VueJS) on kubernetes cluster
$iiidevops_domain_name = get_domain_name('iiidevops');

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-ingress.yaml';
if ($deploy_mode ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{iiidevops_domain_name}}/$iiidevops_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
}
else {
	$cmd = "rm -f $yaml_file";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("$cmd Error!\n$cmd_msg-----\n");
	}
}

$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-ui..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");

# Display Wait 5 min. message
log_print("It takes 3 to 5 minutes to deploy III-DevOps services. Please wait.. \n");

# check deploy status
$isChk=1;
while($isChk) {
	$isChk = 0;
	foreach $line (split(/\n/, `kubectl get pod | grep devops`)) {
		$line =~ s/( )+/ /g;
		($l_name, $l_ready, $l_status, $l_restarts, $l_age) = split(/ /, $line);
		if ($l_name eq 'NAME') {next;}
		if ($l_status ne 'Running') {
			print("[$l_name][$l_status]\n");
			$isChk = 3;
		}
	}
	sleep($isChk);
}

# check iiidevops-api ready
$cmd = "curl -s --max-time 5 --location --request POST '$iiidevops_api/user/login'";
#{ "message": {
#        "username": "Missing required parameter in the JSON body or the post body or the query string" }}
$isChk=1;
while($isChk) {
	print('.');
	$isChk = 0;
	$cmd_msg = `$cmd`;
	$isChk = (index($cmd_msg, 'username')<0)?3:0;
	sleep($isChk);
}
print("\n");

# Add secrets for Rancher all projects
system("$Bin/../devops-api/add_secrets.pl");

# Sync Project templates to GitLab
$sync_key = decode_base64(substr($sync_templ_key,10,63));
system("$Bin/../bin/sync-prj-templ.pl $sync_key");

log_print("----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("\nThe deployment of III-DevOps services has been completed. Please try to connect to the following URL.\n");
log_print("III-DevOps - http://$iiidevops_domain_name\n\n");
