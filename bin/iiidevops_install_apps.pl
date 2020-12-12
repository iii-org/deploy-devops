#!/usr/bin/perl
# Install iiidevops applications script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

# Deploy Redmine on kubernetes cluster
# Modify redmine/redmine-postgresql/redmine-postgresql.yml.tmpl <- {{redmine_db_passwd}} {{nfs_ip}}
$yaml_path = "$Bin/../redmine/redmine-postgresql/";
$yaml_file = $yaml_path.'redmine-postgresql.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{redmine_db_passwd}}/$redmine_db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy redmine-postgresql..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Modify redmine/redmine/redmine-deployment.yml.tmpl <- {{redmine_db_passwd}}
$yaml_path = "$Bin/../redmine/redmine/";
$yaml_file = $yaml_path.'redmine-deployment.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{redmine_db_passwd}}/$redmine_db_passwd/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy redmine..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Deploy SonarQube Server on kubernetes cluster
# Modify sonarqube/sonar-server-deployment.yaml.tmpl <- {{nfs_ip}}
$yaml_path = "$Bin/../sonarqube/";
$yaml_file = $yaml_path.'sonar-server-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy sonarqube..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Deploy DevOps DB (Postgresql) on kubernetes cluster
# Modify devops-db/devopsdb-deployment.yaml.tmpl <- {{db_passwd}} {{nfs_ip}}
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
$cmd = "sudo docker build $yaml_path --tag devops-db:version";
#$cmd .= "; sudo docker push devops-db:version";
print("docker build & push devops-db..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-db..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Deploy DevOps API (Python Flask) on kubernetes cluster
# Modify devops-api/_devopsapi-deployment.yaml.tmpl <- {{db_passwd}} {{db_ip}} {{jwt_secret_key}} {{redmine_ip}} {{redmine_admin_passwd}} {{redmine_api_key}} {{gitlab_url}} {{gitlab_private_token}} {{rancher_url}} {{rancher_admin_password}} {{checkmarx_origin}} {{checkmarx_username}} {{checkmarx_password}} {{checkmarx_secret}} {{sonarqube_ip}}
$yaml_path = "$Bin/../devops-api/";
$yaml_file = $yaml_path.'_devopsapi-deployment.yaml';
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
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
$template =~ s/{{rancher_url}}/$rancher_url/g;
$template =~ s/{{rancher_admin_password}}/$rancher_admin_password/g;
$template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
$template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
$template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
$template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;
$template =~ s/{{sonarqube_ip}}/$sonarqube_ip/g;
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
$cmd = "kubectl apply -f $yaml_path";
print("Deploy devops-ui..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

