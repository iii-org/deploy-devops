#!/usr/bin/perl
# Install sonarqube service script
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$sonarqube_domain_name = ($sonarqube_domain_name eq '')?"sonarqube.iiidevops.$sonarqube_ip.xip.io":$sonarqube_domain_name;

log_print("Install Sonarqube URL: http://$sonarqube_domain_name\n");
# Deploy Sonarqube on kubernetes cluster

# Modify sonarqube/sonarqube-postgresql/sonarqube-postgresql.yml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube-postgresql";
$yaml_file = $yaml_path.'/sonarqube-postgresql.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_db_passwd}}/$sonarqube_db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy sonarqube-postgresql..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");


# Modify sonarqube/sonarqube/sonar-server-deployment.yaml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube";
$yaml_file = $yaml_path.'/sonar-server-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_db_passwd}}/$sonarqube_db_passwd/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
# Modify sonarqube/sonarqube/sonar-server-ingress.yaml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube";
$yaml_file = $yaml_path.'/sonar-server-ingress.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_domain_name}}/$sonarqube_domain_name/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy sonarqube..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy Sonarqube service. Please wait.. \n");

# Check Sonarqube service is working
$cmd = "curl -q -I http://$sonarqube_domain_name";
# Content-Type: text/html;charset=utf-8
$chk_key = 'Content-Type: text/html;charset=utf-8';
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
	log_print("Failed to deploy Sonarqube!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Sonarqube!\n");

# get admin token
# curl --silent --location --request POST 'http://10.50.1.56:31910/api/user_tokens/generate?login=admin&name=API_SERVER' --header 'Authorization: Basic YWRtaW46YWRtaW4='
$cmd = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/user_tokens/generate?login=admin&name=API_SERVER' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END
# response
#{"login":"admin","name":"API_SERVER","token":"3d8d8cb48f0ee8feb889f673bd859fd69be7106b","createdAt":"2021-01-21T07:41:46+0000"}
$hash_msg = decode_json(`$cmd`);
$message = $hash_msg->{'name'};
if ($message eq 'API_SERVER') {
	$sonarqube_admin_token = $hash_msg->{'token'};
	$cmd = "$Bin/../bin/generate_env.pl ask_sonarqube_admin_token $sonarqube_admin_token force";
	write_env();
}
else {
	print("get api token Error : $message \n");
	exit;
}
	
# update admin password
# curl --silent --location --request POST 'http://10.50.1.56:31910/api/users/change_password?login=admin&password=NewPassword&previousPassword=admin' --header 'Authorization: Basic YWRtaW46YWRtaW4='
$cmd = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/users/change_password?login=admin&password=$sonarqube_admin_passwd&previousPassword=admin' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END
$cmd_msg = `$cmd`;
if ($cmd_msg ne '') {
	print("update admin password Error : $cmd_msg \n");
	exit;
}

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}