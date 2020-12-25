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

# **Have to confirm**
## Deploy SonarQube Server on kubernetes cluster
## Modify sonarqube/sonar-server-deployment.yaml.tmpl <- {{nfs_ip}}
#$yaml_path = "$Bin/../sonarqube/";
#$yaml_file = $yaml_path.'sonar-server-deployment.yaml';
#$tmpl_file = $yaml_file.'.tmpl';
#if (!-e $tmpl_file) {
#	print("The template file [$tmpl_file] does not exist!\n");
#	exit;
#}
#$template = `cat $tmpl_file`;
#$template =~ s/{{nfs_ip}}/$nfs_ip/g;
##print("-----\n$template\n-----\n\n");
#open(FH, '>', $yaml_file) or die $!;
#print FH $template;
#close(FH);
#$cmd = "kubectl apply -f $yaml_path";
#print("Deploy sonarqube..\n");
#$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n\n");

# Display Wait 3 min. message
print("It takes 1 to 3 minutes to deploy Redmine & other services. Please wait.. \n");

# check deploy status
#NAME                                  READY   STATUS    RESTARTS   AGE
#redmine-7cdd59f44c-pznd2              1/1     Running   2          124m
#redmine-postgresql-6989b6c4d4-tw2bc   1/1     Running   4          47h
#sonarqube-server-5788564ddc-qn4lf     1/1     Running   1          118m
$isChk=1;
$cmd = "kubectl get pod";
while($isChk) {
	$isChk = 0;
	foreach $line (split(/\n/, `$cmd`)) {
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
$cmd_msg = `$cmd`;
print("$cmd_msg");
print("\nThe deployment of Redmine & other services has been completed. Please Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 9. to continue.\n\n");
