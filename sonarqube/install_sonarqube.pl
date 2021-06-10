#!/usr/bin/perl
# Install sonarqube service script
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($sonarqube_ip eq '') {
	print("The sonarqube_ip in [$p_config] is ''!\n\n");
	exit;
}

$p_force=(lc($ARGV[0]) eq 'force');

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (lc($ARGV[0]) eq 'initial_sonarqube') {
	initial_sonarqube();
	exit;
}

# Check Sonarqube service is working
if (!$p_force && get_service_status('sonarqube')) {
	log_print("Sonarqube is running, I skip the installation!\n\n");
	# Check $sonarqube_admin_token
	if ($sonarqube_admin_token eq '' || lc($sonarqube_admin_token) eq 'skip') {
		initial_sonarqube();
	}
	exit;
}
log_print("Install Sonarqube ..\n");

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
if ($sonarqube_domain_name_tls ne '') {
	if (!check_secert_tls($sonarqube_domain_name_tls)) {
		log_print("The Secert TLS [$sonarqube_domain_name_tls] does not exist in K8s!\n");
		exit;		
	}
	$url = 'https://';
	$ingress_tmpl_file = 'sonar-server-ingress-ssl.yaml.tmpl';
}
else {
	$url = 'http://';
	$ingress_tmpl_file = 'sonar-server-ingress.yaml.tmpl';
}

$yaml_path = "$Bin/../sonarqube/sonarqube/";
$yaml_file = $yaml_path.'sonar-server-ingress.yaml';
if ($sonarqube_domain_name ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_path.$ingress_tmpl_file;
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{sonarqube_domain_name}}/$sonarqube_domain_name/g;
	$template =~ s/{{sonarqube_domain_name_tls}}/$sonarqube_domain_name_tls/g;
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
log_print("Deploy sonarqube..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy Sonarqube service. Please wait.. \n");
sleep(5);

# Check Sonarqube service is working
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('sonarqube'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy Sonarqube!\n");
	exit;
}
$the_url = get_domain_name('sonarqube');
log_print("Successfully deployed Sonarqube! URL - $url$the_url\n");

# Initial SonarQube
initial_sonarqube();
exit;

sub initial_sonarqube {
	if (lc($sonarqube_admin_token) ne 'skip' && $sonarqube_admin_token ne '') {
		log_print("sonarqube_admin_token was initialized, Skip!\n");
		return;
	}
	
	$sonarqube_domain_name = get_domain_name('sonarqube');
	# get admin token
	# curl --silent --location --request POST 'http://10.50.1.56:31910/api/user_tokens/generate?login=admin&name=API_SERVER' --header 'Authorization: Basic YWRtaW46YWRtaW4='
	$cmd_add = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/user_tokens/generate?login=admin&name=API_SERVER' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END
	# response
	#{"login":"admin","name":"API_SERVER","token":"3d8d8cb48f0ee8feb889f673bd859fd69be7106b","createdAt":"2021-01-21T07:41:46+0000"}
	$cmd_del = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/user_tokens/revoke?login=admin&name=API_SERVER' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END

	$chk_key='API_SERVER';
	$isChk=1;
	$count=0;
	$wait_sec=300;
	while($isChk && $count<$wait_sec) {
		log_print('.');
		$cmd_msg = `$cmd_add`;
		#print("1:$cmd_msg\n");
		if (index($cmd_msg, 'already exists')>=0) {
			`$cmd_del`;
			sleep(1);
			$cmd_msg = `$cmd_add`;
			#print("2:$cmd_msg\n");
		}
		$isChk = (index($cmd_msg, $chk_key)<0)?3:0;
		$count = $count + $isChk;
		sleep($isChk);
	}
	log_print("\n$cmd_msg\n-----\n");
	$message = '';
	if (!$isChk) {
		$hash_msg = decode_json($cmd_msg);
		$message = $hash_msg->{'name'};
	}
	if ($message eq $chk_key) {
		$sonarqube_admin_token = $hash_msg->{'token'};
		$cmd = "$Bin/../bin/generate_env.pl sonarqube_admin_token $sonarqube_admin_token force";
		$cmd_msg = `$cmd`;
		log_print("$cmd_msg");
		log_print("get & set admin token OK!\n");
	}
	else {
		log_print("get admin token Error : $message \n");
		return;
	}

	# Wait 3 Secs
	sleep(3);

	# Setting default sonarqube group template permission ( admin, codeviewer, issueadmin, securityhotspotadmin, scan, user ) 
	$permission_str = 'admin,codeviewer,issueadmin,securityhotspotadmin,scan,user';
	# Add sonar-admin permissions
	# curl --location --request POST 'http://10.50.1.56:31910/api/permissions/add_group_to_template?templateId=default_template&groupName=sonar-administrators&permission=codeviewer' --header 'Authorization: Basic YWRtaW46YWRtaW4='
	$cmd_add_permission = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/permissions/add_group_to_template?templateId=default_template&groupName=sonar-administrators&permission=%%permission%%' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END

	# Remove sonar-user permissions
	# curl --location --request POST 'http://10.50.1.56:31910/api/permissions/remove_group_from_template?templateId=default_template&groupName=sonar-users&permission=admin' --header 'Authorization: Basic YWRtaW46YWRtaW4='
	$cmd_remove_permission = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/permissions/remove_group_from_template?templateId=default_template&groupName=sonar-users&permission=%%permission%%' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END
	
	foreach $permission (split(',', $permission_str)) {
		$cmd = $cmd_add_permission;
		$cmd =~ s/%%permission%%/$permission/g;
		$cmd_msg = `$cmd`;
		if ($cmd_msg ne '') {
			log_print("Add group sonar-administrators $permission permission Error : $cmd_msg \n");
		}
		else {
			log_print("Add group sonar-administrators $permission permission OK!\n");
		}
		
		$cmd = $cmd_remove_permission;
		$cmd =~ s/%%permission%%/$permission/g;
		$cmd_msg = `$cmd`;
		if ($cmd_msg ne '') {
			log_print("Remove group sonar-users $permission permission Error : $cmd_msg \n");
		}
		else {
			log_print("Remove group sonar-users $permission permission OK!\n");
		}			
	}

	# update admin password
	# curl --silent --location --request POST 'http://10.50.1.56:31910/api/users/change_password?login=admin&password=NewPassword&previousPassword=admin' --header 'Authorization: Basic YWRtaW46YWRtaW4='
	$cmd = <<END;
curl --silent --location --request POST 'http://$sonarqube_domain_name/api/users/change_password?login=admin&password=$sonarqube_admin_passwd&previousPassword=admin' --header 'Authorization: Basic YWRtaW46YWRtaW4='

END
	$cmd_msg = `$cmd`;
	if ($cmd_msg ne '') {
		log_print("update admin password Error : $cmd_msg \n");
		exit;
	}
	log_print("update admin password OK!\n");

	return;
}