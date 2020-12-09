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
# Modify redmine/redmine-postgresql/redmine-postgresql.yml.tmpl <- {{postgres_password}} {{nfs_ip}}
$yaml_path = "$Bin/../redmine/redmine-postgresql/";
$yaml_file = $yaml_path.'redmine-postgresql.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{postgres_password}}/$postgres_password/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
#print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
print("Deploy redmine-postgresql..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n\n");

# Modify redmine/redmine/redmine-deployment.yml.tmpl <- {{postgres_password}}
$yaml_path = "$Bin/../redmine/redmine/";
$yaml_file = $yaml_path.'redmine-deployment.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{postgres_password}}/$postgres_password/g;
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

# Deploy DevOps DB (Postgresql) on kubernetes cluster
# Modify devops-db/devopsdb-deployment.yaml.tmpl <- {{postgres_password}}

# Deploy DevOps API (Python Flask) on kubernetes cluster
# Modify devops-api/_devopsapi-deployment.yaml.tmpl <- {{postgres_password}} {{db_ip}} ... {{gitlab_url}}

# Deploy DevOps UI (VueJS) on kubernetes cluster

