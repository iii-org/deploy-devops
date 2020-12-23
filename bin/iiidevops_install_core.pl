#!/usr/bin/perl
# Install iiidevops core script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

# Check kubernetes cluster info.
$cmd = "kubectl cluster-info";
print("Check kubernetes cluster info..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");
$cmd_msg =~  s/\e\[[\d;]*[a-zA-Z]//g; # Remove ANSI color
if (index($cmd_msg, 'Kubernetes control plane is running')<0 || index($cmd_msg, 'CoreDNS is running')<0) {
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
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-db..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

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
$template =~ s/{{gitlab_url}}/$gitlab_url/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_url}}/$rancher_url/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{harbor_url}}/$harbor_url/g;
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
#NAME                                  READY   STATUS    RESTARTS   AGE
#redmine-7cdd59f44c-hz4qz              1/1     Running   2          40m
#redmine-postgresql-6989b6c4d4-tw2bc   1/1     Running   1          40m
#sonarqube-server-5788564ddc-ld4mp     1/1     Running   1          40m
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
