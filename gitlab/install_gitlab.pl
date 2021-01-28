#!/usr/bin/perl
# Install GitLab service script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($gitlab_ip eq '') {
	print("The gitlab_ip in [$p_config] is ''!\n\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$gitlab_domain_name = get_domain_name('gitlab');

log_print("Install GitLab URL: http://$gitlab_domain_name\n");
# Deploy GitLab on kubernetes cluster

# Modify gitlab/gitlab-deployment.yml.tmpl
$yaml_path = "$Bin/../gitlab/";
$yaml_file = $yaml_path.'gitlab-deployment.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

# Modify gitlab/gitlab-ingress.yaml.tmpl
$yaml_path = "$Bin/../gitlab/";
$yaml_file = $yaml_path.'gitlab-ingress.yml';
#if ($deploy_mode ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
#}
#else {
#	$cmd = "rm -f $yaml_file";
#	$cmd_msg = `$cmd 2>&1`;
#	if ($cmd_msg ne '') {
#		log_print("$cmd Error!\n$cmd_msg-----\n");
#	}
#}

$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy GitLab..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy GitLab service. Please wait.. \n");

# Check GitLab service is working
$cmd = "curl -q -I http://$gitlab_domain_name/users/sign_in";
#HTTP/1.1 200 OK
$chk_key = '200 OK';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("\n$cmd_msg-----\n");
if ($isChk) {
	log_print("Failed to deploy GitLab!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed GitLab!\n");

exit;
