#!/usr/bin/perl
# Install iiidevops core script
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
$is_offline = defined($ARGV[0])?lc($ARGV[0]):''; # 'offline' : run sync-prj-templ-offline.pl && add_secrets.pl offline
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check $Bin/github/* to determine whether to use ISO installation
if (-e "$Bin/github/") {
	$cmd_msg = `ls $Bin/github/ | wc -l`;
	$cmd_msg =~ s/\n|\r//g;
	if ($cmd_msg >0 ) {
		$is_offline = 'offline';
	}
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

# Deploy DevOps DB (Postgresql) on kubernetes cluster
$yaml_path = "$Bin/../devops-db/";
$yaml_file = $yaml_path.'devopsdb-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit(1);
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
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n\n");

log_print("Deploy devops-db..");
$isChk=1;
$count=0;
$wait_sec=60;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!chk_svcipport('localhost', 31403))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
if ($isChk) {
	log_print("Failed to deploy devops-db!\n");
	exit(1);
}
log_print("OK!\n");

# check & create NFS redis dir
if (!-e "$nfs_dir/devops-redis") {
	$cmd =<<END;
mkdir -p $nfs_dir/devops-redis;
chmod 777 $nfs_dir/devops-redis;
END
	system($cmd);
}


# Check & Set deploy version
$t_now_ver = get_nexus_info('deploy_version');
$t_set_ver = ($iiidevops_ver eq 'develop')?'develop':'V'.$iiidevops_ver;
if ($t_now_ver eq 'Err1') {
	print("If this is the first installation, ignore this error message!\n");
}
elsif ($t_now_ver eq '') {
	$t_ret_ver=set_nexus_deploy_version($t_set_ver);
	if ($t_ret_ver eq $t_set_ver) {
		print("Set deploy version to [$t_set_ver] OK!\n");
	}
	else {
		print("Failed to set deploy version : [$t_ret_ver]!!!\n");
		exit(1);
	}
}
else {
	# Get from version center
	$uuid = get_nexus_info('deployment_uuid');
	if (length($uuid)==36) {
		($deploy_version, $api_tag, $ui_tag) = get_version_center_info('https://version-center.iiidevops.org', $uuid);
		if (index($deploy_version, 'Err')==0) {
			print("Failed to get info from version center : [$deploy_version]!!!\n");
			# FIXME - There will be problems when the image tag of API and UI are different
			$t_now_ver =~ s/V//;
			$iiidevops_ver = ($deploy_version eq 'develop')?'develop':$t_now_ver;			
		}
		else {
			# FIXME - There will be problems when the image tag of API and UI are different
			$iiidevops_ver = ($deploy_version eq 'develop')?'develop':$api_tag;
		}
	}
}

# api_replicas
$v_replicas = get_k8sdeploy('Replicas', 'devopsapi');
$api_replicas = (index($v_replicas, 'ERR')<0)?$v_replicas:1;

# ui_replicas
$v_replicas = get_k8sdeploy('Replicas', 'devopsui');
$ui_replicas = (index($v_replicas, 'ERR')<0)?$v_replicas:1;

# iiidevops_ver
$iiidevops_ver = ($iiidevops_ver eq '')?'1':$iiidevops_ver;

# imagePullPolicy
$image_pull_policy = ($iiidevops_ver eq 'develop')?'Always':'IfNotPresent';

# redmine_url
$v_redmine_domain_name = get_domain_name('redmine');
$v_http = ($redmine_domain_name_tls ne '')?'https':'http';
$redmine_url = $v_http.'://'.$v_redmine_domain_name;

# gitlab_url
$v_gitlab_domain_name = get_domain_name('gitlab');
$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
$gitlab_url = $v_http.'://'.$v_gitlab_domain_name;

# harbor_internal_base_url
# harbor_internal_basr_url will use http after TLS upgrade 
$harbor_internal_base_url = 'https://harbor-harbor-core/api/v2.0';

# sonarqube_url
$v_sonarqube_domain_name = get_domain_name('sonarqube');
$v_http = ($sonarqube_domain_name_tls ne '')?'https':'http';
$sonarqube_url = $v_http.'://'.$v_sonarqube_domain_name;

# deployment_name
$t_hostname = `hostname`;
$t_hostname =~ s/\n|\r//g;
$deployment_name = ($iiidevops_domain_name ne '')?$iiidevops_domain_name:$t_hostname;

# check & create NFS dir
if (!-e "$nfs_dir/devops-data") {
	$cmd =<<END;
mkdir -p $nfs_dir/devops-data;
chmod 777 $nfs_dir/devops-data;
END
	system($cmd);
}

# Deploy DevOps API (Python Flask) on kubernetes cluster
$yaml_path = "$Bin/../devops-api/";
$yaml_file = $yaml_path.'devopsapi-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit(1);
}

$template = `cat $tmpl_file`;
$template =~ s/{{api_replicas}}/$api_replicas/g;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
$template =~ s/{{image_pull_policy}}/$image_pull_policy/g;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{db_ip}}/$db_ip/g;
$template =~ s/{{jwt_secret_key}}/$jwt_secret_key/g;
$template =~ s/{{redmine_url}}/$redmine_url/g;
$template =~ s/{{redmine_admin_passwd}}/$redmine_admin_passwd/g;
$template =~ s/{{redmine_api_key}}/$redmine_api_key/g;
$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
$template =~ s/{{gitlab_url}}/$gitlab_url/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_ip}}/$rancher_ip/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{harbor_internal_base_url}}/$harbor_internal_base_url/g;
$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
$template =~ s/{{k8sctl_domain_name}}/$k8sctl_domain_name/g;
$template =~ s/{{ingress_domain_name}}/$ingress_domain_name/g;
$template =~ s/{{ingress_domain_name_tls}}/$ingress_domain_name_tls/g;
$template =~ s/{{sonarqube_url}}/$sonarqube_url/g;
$template =~ s/{{sonarqube_admin_token}}/$sonarqube_admin_token/g;
$template =~ s/{{admin_init_login}}/$admin_init_login/g;
$template =~ s/{{admin_init_email}}/$admin_init_email/g;
$template =~ s/{{admin_init_password}}/$admin_init_password/g;
$template =~ s/{{deployment_name}}/$deployment_name/g;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
$template =~ s/{{first_ip}}/$first_ip/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
$template =~ s/{{deploy_env}}/$deploy_env/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy devops-api..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");

# Deploy DevOps Redis on kubernetes cluster
$yaml_path = "$Bin/../devops-redis/";
$yaml_file = $yaml_path.'devops-redis-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit(1);
}
$template = `cat $tmpl_file`;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");

# Deploy DevOps UI (VueJS) on kubernetes cluster
$v_iiidevops_domain_name = get_domain_name('iiidevops');

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit(1);
}
$template = `cat $tmpl_file`;
$template =~ s/{{ui_replicas}}/$ui_replicas/g;
$template =~ s/{{iiidevops_ver}}/$iiidevops_ver/g;
$template =~ s/{{image_pull_policy}}/$image_pull_policy/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

if ($iiidevops_domain_name_tls ne '') {
	# Check & import cert files
	$cert_path = "$nfs_dir/deploy-config/devops-cert/";
	$cer_file = "$cert_path/fullchain.pem";
	if (!-e $cer_file) {
		log_print("The cert file [$cer_file] does not exist!\n");
		exit(1);
	}
	$key_file = "$cert_path/privkey.pem";
	if (!-e $key_file) {
		log_print("The key file [$key_file] does not exist!\n");
		exit(1);
	}
	system("$Bin/../bin/import-secret-tls.pl $iiidevops_domain_name_tls $cer_file $key_file");
	if (!check_secert_tls($iiidevops_domain_name_tls)) {
		log_print("The Secert TLS [$iiidevops_domain_name_tls] does not exist in K8s!\n");
		exit(1);		
	}
	$url = 'https://';
	$ingress_tmpl_file = 'devopsui-ingress-ssl.yaml.tmpl';
}
else {
	$url = 'http://';
	$ingress_tmpl_file = 'devopsui-ingress.yaml.tmpl';
}

$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-ingress.yaml';
if ($deploy_mode ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_path.$ingress_tmpl_file;
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit(1);
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{iiidevops_domain_name}}/$v_iiidevops_domain_name/g;
	$template =~ s/{{iiidevops_domain_name_tls}}/$iiidevops_domain_name_tls/g;
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
sleep(5);

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
$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

$isChk=1;
$count=0;
$wait_sec=300;
while($isChk) {
	print('.');
	$isChk = 0;
	$cmd_msg = `$cmd`;
	$isChk = (index($cmd_msg, 'username')<0)?3:0;
	sleep($isChk);

	$count = $count + $isChk;
	if($count>$wait_sec){
		$cmd_msg = `$cmd_kubectl rollout restart deployment devopsdb devopsapi devops-redis`;
		print("Restart deployment: devopsdb devopsapi devops-redis \n");
		sleep(10);
	}
}
print("\n");

# Check Rancher Cluster Name is iiidevops-k8
if (!is_rancher_default_name_ok()) {
	log_print("Rancher cluster name IS NOT iiidevops-k8s! Please refer to Step 4 at https://github.com/iii-org/deploy-devops \n");
	exit(1);
}
log_print("Rancher cluster name is already iiidevops-k8s!\n");

# Add secrets for Rancher all projects
system("$Bin/../devops-api/add_secrets.pl");

# Sync Project templates to GitLab && Add Catalog
if ($is_offline eq 'offline') {
	system("$Bin/../bin/sync_chart_index.pl gitlab_offline");
	system("$Bin/../bin/sync-prj-templ-offline.pl");
}
else {
	if ($sync_templ_key ne '') {
		system("$Bin/../bin/sync_chart_index.pl");
		system("$Bin/../bin/sync-prj-templ.pl $sync_templ_key");
	}
	else {
		log_print("Sync III DevOps Templates no GitHub key ! Please refer to Step 8 at https://github.com/iii-org/deploy-devops \n");
	}
}

log_print("----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("\nThe deployment of III-DevOps services has been completed. Please try to connect to the following URL.\n");
log_print("III-DevOps - $url$v_iiidevops_domain_name\n\n");
