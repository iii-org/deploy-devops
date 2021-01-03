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

# Check kubernetes status.
$cmd = "kubectl get pod | grep redmine | tail -1";
print("Check kubernetes status..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");
#$cmd_msg =~  s/\e\[[\d;]*[a-zA-Z]//g; # Remove ANSI color
if (index($cmd_msg, 'Running')<0) {
	print("The Kubernetes cluster is not working properly!\n");
	exit;
}

# Create Namespace on kubernetes cluster
$cmd = "kubectl apply -f $Bin/../kubernetes/namespaces/account.yaml";
print("Create Namespace on kubernetes cluster..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");
if (index($cmd_msg, 'namespace/account created')<0 && index($cmd_msg, 'namespace/account unchanged')<0) {
	print("Failed to create namespace on kubernetes cluster!\n");
	exit;
}
print("Create namespace on kubernetes cluster OK!\n");

# # Create Quota on kubernetes cluster
# $cmd = "kubectl apply -f $Bin/../kubernetes/quota/";
# print("Create Quota on kubernetes cluster..\n");
# $cmd_msg = `$cmd`;
# print("-----\n$cmd_msg\n-----\n\n");
# #limitrange/resouce-limit-range created
# #resourcequota/quota-test created
# #
# #limitrange/resouce-limit-range configured
# #resourcequota/quota-test unchanged
# if ((index($cmd_msg, 'limitrange/resouce-limit-range created')>=0 || index($cmd_msg, 'limitrange/resouce-limit-range configured')>=0) && (index($cmd_msg, 'resourcequota/quota-test created')>=0 || index($cmd_msg, 'resourcequota/quota-test unchanged')>=0)) {
	# print("Create quota on kubernetes cluster OK!\n");
# }
# else {
	# print("Failed to create quota on kubernetes cluster!\n");
	# exit;
# }
# # Create Secrets on kubernetes cluster
# $yaml_path = "$Bin/../kubernetes/secrets/";
# # api-origin.yaml
# $yaml_file = $yaml_path.'api-origin.yaml';
# $tmpl_file = $yaml_file.'.tmpl';
# if (!-e $tmpl_file) {
	# print("The template file [$tmpl_file] does not exist!\n");
	# exit;
# }
# $template = `cat $tmpl_file`;
# $string = encode_base64($iiidevops_api);
# $string =~ s/\n|\r//;
# $template =~ s/{{iiidevops_api}}/$string/g;
# #print("-----\n$template\n-----\n\n");
# open(FH, '>', $yaml_file) or die $!;
# print FH $template;
# close(FH);
# $cmd = "kubectl apply -f $yaml_file";
# print("Create Secrets $yaml_file..\n");
# $cmd_msg = `$cmd`;
# print("-----\n$cmd_msg\n-----\n");
# # checkmarx-secret.yaml
# $yaml_file = $yaml_path.'checkmarx-secret.yaml';
# $tmpl_file = $yaml_file.'.tmpl';
# if (!-e $tmpl_file) {
	# print("The template file [$tmpl_file] does not exist!\n");
	# exit;
# }
# $template = `cat $tmpl_file`;
# $check_interval = 3000;
# $string = encode_base64($check_interval);
# $string =~ s/\n|\r//;
# $template =~ s/{{check_interval}}/$string/g;
# $string = encode_base64($checkmarx_secret);
# $string =~ s/\n|\r//;
# $template =~ s/{{checkmarx_secret}}/$string/g;
# $string = encode_base64($checkmarx_origin);
# $string =~ s/\n|\r//;
# $template =~ s/{{checkmarx_origin}}/$string/g;
# $string = encode_base64($checkmarx_username);
# $string =~ s/\n|\r//;
# $template =~ s/{{checkmarx_username}}/$string/g;
# $string = encode_base64($checkmarx_password);
# $string =~ s/\n|\r//;
# $template =~ s/{{checkmarx_password}}/$string/g;
# #print("-----\n$template\n-----\n\n");
# open(FH, '>', $yaml_file) or die $!;
# print FH $template;
# close(FH);
# $cmd = "kubectl apply -f $yaml_file";
# print("Create Secrets $yaml_file..\n");
# $cmd_msg = `$cmd`;
# print("-----\n$cmd_msg\n-----\n");
# # gitlab-token.yaml
# $yaml_file = $yaml_path.'gitlab-token.yaml';
# $tmpl_file = $yaml_file.'.tmpl';
# if (!-e $tmpl_file) {
	# print("The template file [$tmpl_file] does not exist!\n");
	# exit;
# }
# $template = `cat $tmpl_file`;
# $string = encode_base64($gitlab_private_token);
# $string =~ s/\n|\r//;
# $template =~ s/{{gitlab_private_token}}/$string/g;
# #print("-----\n$template\n-----\n\n");
# open(FH, '>', $yaml_file) or die $!;
# print FH $template;
# close(FH);
# $cmd = "kubectl apply -f $yaml_file";
# print("Create Secrets $yaml_file..\n");
# $cmd_msg = `$cmd`;
# print("-----\n$cmd_msg\n-----\n");
# # jwt-token.yaml
# $yaml_file = $yaml_path.'jwt-token.yaml';
# $tmpl_file = $yaml_file.'.tmpl';
# if (!-e $tmpl_file) {
	# print("The template file [$tmpl_file] does not exist!\n");
	# exit;
# }
# $template = `cat $tmpl_file`;
# $string = encode_base64($jwt_secret_key);
# $string =~ s/\n|\r//;
# $template =~ s/{{jwt_secret_key}}/$string/g;
# #print("-----\n$template\n-----\n\n");
# open(FH, '>', $yaml_file) or die $!;
# print FH $template;
# close(FH);
# $cmd = "kubectl apply -f $yaml_file";
# print("Create Secrets $yaml_file..\n");
# $cmd_msg = `$cmd`;
# print("-----\n$cmd_msg\n-----\n");


# Check if Gitlab/Rancher/Harbor/Redmine services are running well
# GitLab
$isChk=1;
$count=0;
while($isChk && $count<10) {
	print('.');
	$cmd_msg = `nc -z -v $gitlab_ip 80 2>&1`;
	# Connection to 10.20.0.71 6443 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
print("-----Check GitLab-----\n$cmd_msg");
if ($isChk) {
	print("GitLab is not working well!\n");
	exit;
}

# Rancher
$isChk=1;
$count=0;
while($isChk && $count<10) {
	print('.');
	$cmd_msg = `nc -z -v $rancher_ip 6443 2>&1`;
	# Connection to 10.20.0.71 6443 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
print("-----Check Rancher-----\n$cmd_msg");
if ($isChk) {
	print("Rancher is not working well!\n");
	exit;
}

# Harbor
$isChk=1;
$count=0;
while($isChk && $count<10) {
	print('.');
	$cmd_msg = `nc -z -v $harbor_ip 5443 2>&1`;
	# Connection to 10.20.0.71 5443 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
print("-----Check Harbor-----\n$cmd_msg");
if ($isChk) {
	print("Harbor is not working well!\n");
	exit;
}

# Redmine
$isChk=1;
$count=0;
while($isChk && $count<10) {
	print('.');
	$cmd_msg = `nc -z -v $redmine_ip 32748 2>&1`;
	# Connection to 10.20.0.72 32748 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
print("-----Check Redmine-----\n$cmd_msg");
if ($isChk) {
	print("Redmine is not working well!\n");
	exit;
}

# Deploy DevOps DB (Postgresql) on kubernetes cluster
$yaml_path = "$Bin/../devops-db/";
$yaml_file = $yaml_path.'devopsdb-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-db..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n\n");

# Check the database is ready!
$isChk=1;
while($isChk) {
	print('.');
	$cmd_msg = `nc -z -v $db_ip 31403 2>&1`;
	# Connection to 192.168.11.205 31403 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	sleep($isChk);
}
print("OK!\n");

# Deploy DevOps API (Python Flask) on kubernetes cluster
$yaml_path = "$Bin/../devops-api/";
$yaml_file = $yaml_path.'devopsapi-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{db_passwd}}/$db_passwd/g;
$template =~ s/{{db_ip}}/$db_ip/g;
$template =~ s/{{jwt_secret_key}}/$jwt_secret_key/g;
$template =~ s/{{redmine_ip}}/$redmine_ip/g;
$template =~ s/{{redmine_admin_passwd}}/$redmine_admin_passwd/g;
$template =~ s/{{redmine_api_key}}/$redmine_api_key/g;
$template =~ s/{{gitlab_url}}/$gitlab_ip/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_ip}}/$rancher_ip/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{harbor_ip}}/$harbor_ip/g;
$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
$template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
$template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
$template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
$template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;
$template =~ s/{{webinspect_base_url}}/$webinspect_base_url/g;
$template =~ s/{{sonarqube_ip}}/$sonarqube_ip/g;
$template =~ s/{{admin_init_login}}/$admin_init_login/g;
$template =~ s/{{admin_init_email}}/$admin_init_email/g;
$template =~ s/{{admin_init_password}}/$admin_init_password/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-api..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");


# Deploy DevOps UI (VueJS) on kubernetes cluster
$yaml_path = "$Bin/../devops-ui/";
$yaml_file = $yaml_path.'devopsui-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-ui..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Display Wait 5 min. message
print("It takes 3 to 5 minutes to deploy III-DevOps services. Please wait.. \n");

# check deploy status
$isChk=1;
while($isChk) {
	$isChk = 0;
	foreach $line (split(/\n/, `kubectl get pod`)) {
		$line =~ s/( )+/ /g;
		($l_name, $l_ready, $l_status, $l_restarts, $l_age) = split(/ /, $line);
		if ($l_name eq 'NAME') {next;}
		if ($l_status ne 'Running') {
			print("[$l_name][$l_status]\n");
			$isChk ++;
		}
	}
	sleep($isChk);
}

print("\nThe deployment of III-DevOps services has been completed. Please try to connect to the following URL.\nIII-DevOps URL - $iiidevops_url\n");
