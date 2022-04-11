#!/usr/bin/perl
# Install sonarqube service script
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit(1);
}
require($p_config);

if ($sonarqube_ip eq '') {
	print("The sonarqube_ip in [$p_config] is ''!\n\n");
	exit(1);
}

$p_force=(lc($ARGV[0]) eq 'force');

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (lc($ARGV[0]) eq 'initial_sonarqube') {
	$initial_sonarqube = initial_sonarqube();
	if($initial_sonarqube){
		exit(1);
	}
	exit;
}

# Check Sonarqube service is working
if (!$p_force && get_service_status('sonarqube')) {
	log_print("Sonarqube is running, I skip the installation!\n\n");
	# Check $sonarqube_admin_token
	if ($sonarqube_admin_token eq '' || lc($sonarqube_admin_token) eq 'skip') {
		$initial_sonarqube = initial_sonarqube();
		if($initial_sonarqube){
			exit(1);
		}
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
	exit(1);
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
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");
log_print("Deploy sonarqube-postgresql..");

$isChk=1;
$count=0;
$wait_sec=60;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!chk_svcipport('localhost', 32750))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
if ($isChk) {
	log_print("Failed to deploy Sonarqube!\n");
	exit(1);
}
log_print("OK!\n");

# Modify sonarqube/sonarqube/sonar-server-deployment.yaml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube";
$yaml_file = $yaml_path.'/sonar-server-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit(1);
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_db_passwd}}/$sonarqube_db_passwd/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

# Modify sonarqube/sonarqube/sonar-server-ingress.yaml.tmpl
if ($sonarqube_domain_name_tls ne '') {
	# Check & import cert files
	$cert_path = "$nfs_dir/deploy-config/";
	$cert_path = (-e $cert_path.'sonarqube-cert/')?$cert_path.'sonarqube-cert/':$cert_path.'devops-cert/';
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
	system("$Bin/../bin/import-secret-tls.pl $sonarqube_domain_name_tls $cer_file $key_file");
	if (!check_secert_tls($sonarqube_domain_name_tls)) {
		log_print("The Secert TLS [$sonarqube_domain_name_tls] does not exist in K8s!\n");
		exit(1);
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
		exit(1);
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
	exit(1);
}
$the_url = get_domain_name('sonarqube');
log_print("Successfully deployed Sonarqube! URL - $url$the_url\n");

# Initial SonarQube
$initial_sonarqube = initial_sonarqube();
if($initial_sonarqube){
	exit(1);
}
exit;

sub initial_sonarqube {
	if (lc($sonarqube_admin_token) ne 'skip' && $sonarqube_admin_token ne '') {
		log_print("sonarqube_admin_token was initialized, Skip!\n");
		return;
	}
	
	# Generate admin token
	$chk_key='API_SERVER';
	$isChk=1;
	$count=0;
	$wait_sec=300;
	while($isChk && $count<$wait_sec) {
		log_print('.');
		$cmd_msg = call_sonarqube_api('POST', 'user_tokens/generate?login=admin&name=API_SERVER');
		#print("1:$cmd_msg\n");
		if (index($cmd_msg, 'already exists')>=0) {
			call_sonarqube_api('POST', 'user_tokens/revoke?login=admin&name=API_SERVER');
			sleep(1);
			$cmd_msg = call_sonarqube_api('POST', 'user_tokens/generate?login=admin&name=API_SERVER');
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
		return 1;
	}

	# Wait 3 Secs
	sleep(3);

	# Find default_template
	$cmd_msg = call_sonarqube_api('GET', 'permissions/search_templates');
	if (index($cmd_msg, 'templateId')<0) {
		log_print("get default_template Error : $cmd_msg \n");
		return 1;
	}
	$hash_msg = decode_json($cmd_msg);
	$templateId = $hash_msg->{'defaultTemplates'}[0]->{'templateId'};
	log_print("get default_template ID : $templateId \n");
	
	# Setting default sonarqube group template permission ( admin, codeviewer, issueadmin, securityhotspotadmin, scan, user ) 
	$permission_str = 'admin,codeviewer,issueadmin,securityhotspotadmin,scan,user';	
	foreach $permission (split(',', $permission_str)) {
		$cmd_msg = call_sonarqube_api('POST', "permissions/add_group_to_template?templateId=$templateId&groupName=sonar-administrators&permission=$permission");
		if ($cmd_msg ne '') {
			log_print("Add group sonar-administrators $permission permission Error : $cmd_msg \n");
		}
		else {
			log_print("Add group sonar-administrators $permission permission OK!\n");
		}
		
		$cmd_msg = call_sonarqube_api('POST', "permissions/remove_group_from_template?templateId=$templateId&groupName=sonar-users&permission=$permission");
		if ($cmd_msg ne '') {
			log_print("Remove group sonar-users $permission permission Error : $cmd_msg \n");
		}
		else {
			log_print("Remove group sonar-users $permission permission OK!\n");
		}			
	}
	
	# update admin password
	$url_sonarqube_admin_passwd = url_encode($sonarqube_admin_passwd);
	$cmd_msg = call_sonarqube_api('POST', "users/change_password?login=admin&password=$url_sonarqube_admin_passwd&previousPassword=admin");
	if ($cmd_msg ne '') {
		log_print("update admin password Error : $cmd_msg \n");
		exit(1);
	}
	log_print("update admin password OK!\n");

	return;
}