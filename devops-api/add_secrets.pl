#!/usr/bin/perl
# Add Secrets & Registry & Catalogs for all Rancher Projects
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
require("$Bin/../lib/common_lib.pl");

$is_offline = defined($ARGV[0])?lc($ARGV[0]):''; # 'offline' : run catalog url to gitlab
$secrets_path = "$Bin/secrets/";
$api_key = '';

#-----
# Add Secrets Credentials
#-----
print("\nAdd Secrets Credentials\n-----\n");
# Get secrets List
$hash_secrets = {};
$secrets_num = get_secrets_api();
$secrets_name_list = '';
foreach $item (@{ $hash_secrets->{'data'} }) {
        $secrets_name_list .= "[$item->{'name'}]";
}

# nexus
$name = 'nexus';
$key_value{'api-origin'} = $iiidevops_api;
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# checkmarx
$name = 'checkmarx';
$key_value{'client-secret'} = $checkmarx_secret;
$key_value{'cm-url'} = $checkmarx_origin;
$key_value{'username'} = $checkmarx_username;
$key_value{'password'} = $checkmarx_password;
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# webinspect
$name = 'webinspect';
$key_value{'wi-base-url'} = $webinspect_base_url;
$key_value{'wi-type'} = $webinspect_type;
$key_value{'wi-username'} = $webinspect_username;
$key_value{'wi-password'} = $webinspect_password;
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# rancher
$name = 'rancher';
$rancher_hostname=($deploy_mode eq 'IP')?$rancher_ip.':31443':$rancher_domain_name;
$key_value{'rancher-url'} = 'https://'.$rancher_hostname;
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# sonarqube
$name = 'sonarqube';
$key_value{'sonar-url'} = 'http://'.$sonarqube_ip.':31910';
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# harbor
$name = 'harbor';
$key_value{'harbor-local'} = ($harbor_domain_name eq '')?$harbor_ip.':32443':$harbor_domain_name;
if (index($secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}


#-----
# Add Registry Credentials
#-----
print("\nAdd Registry Credentials\n-----\n");
# Get registry List
$hash_registry = {};
$registry_num = get_registry_api();
$registry_name_list = '';
foreach $item (@{ $hash_registry->{'data'} }) {
        $registry_name_list .= "[$item->{'name'}]";
}

# harbor-local
$name = 'harbor-local';
$url = ($harbor_domain_name eq '')?$harbor_ip.':32443':$harbor_domain_name;
$key_value{'url'} = $url;
$key_value{'username'} = 'admin';
$key_value{'password'} = $harbor_admin_password;
if (index($registry_name_list, '['.$name.']')<0) {
	$ret_msg = add_registry($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}


#-----
# Add Apps Catalogs
#-----
print("\nAdd Apps Catalogs\n-----\n");
# Get catalogs List
$hash_catalogs = {};
$catalogs_num = get_catalogs_api();
$catalogs_name_list = '';
$helm_catalog_url = '';
foreach $item (@{ $hash_catalogs->{'data'} }) {
        $catalogs_name_list .= "[$item->{'name'}]";
}

if ($is_offline eq 'offline') {
	$gitlab_domain_name = get_domain_name('gitlab');
	$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
	$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';

	$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/projects";
	print("Get GitLab project list..\n");
	$cmd_msg = `$cmd`;
	if (index($cmd_msg, '"message"')>0) {
		log_print("Get GitLab projects Error!\n---\n$cmd_msg\n---\n");
		exit;
	}

	$hash_gitlab_project = decode_json($cmd_msg);
	$prj_name_list = '';
	$helm_catalog = 'devops-charts-pack-and-index';
	foreach $project_hash (@ {$hash_gitlab_project}) {
		$prj_name_list .= '['.$project_hash->{'name'}.']';
		if ($project_hash->{'name'} eq $helm_catalog) {
			$helm_catalog_url = $project_hash->{'web_url'};
		}
	}

	if (index($prj_name_list, '['.$helm_catalog.']')<0) {
		#Create Gitlab Helm Catalog Project 
		my $p_tar = "$Bin/$helm_catalog.tar.gz";
		if (!-e $p_tar) {
			print("The file [$p_tar] does not exist!\n");
			exit; 
		}

		$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"devops-charts-pack-and-index\",\"visibility\":\"public\"}' $v_http://$gitlab_domain_name/api/v4/projects";
		$cmd_msg = `$cmd`;
		$ret = '';
		if (index($cmd_msg, "devops-charts-pack-and-index")>0){
			$hash_msg = decode_json($cmd_msg);
			$ret = $hash_msg->{'name'};
			$helm_catalog_url = $hash_msg->{'web_url'};
			$git_url = $hash_msg->{'http_url_to_repo'};
			print("Create $ret Success\n");
			# push Helm Catalog Project to GitLab
			system("git config --global user.name \"Administrator\"");
			system("git config --global user.password \"$gitlab_root_passwd\"");
			system("git config --global credential.helper store");
			chdir "$Bin";
			$tar_msg = `tar zxvf $Bin/$helm_catalog.tar.gz`;
			chdir "$Bin/$helm_catalog";
			$git_msg = `git remote rename origin old-origin; git remote add origin $git_url; git push -u origin --all; git push -u origin --tags`;
			chdir "$Bin";
			$rm_tar_msg = `rm -rf $Bin/$helm_catalog`;
			print("Add Gitlab Helm Catalog [$helm_catalog] templates");
		}
	}
}
print("helm_catalog_url : $helm_catalog_url");
# iii-dev-charts3
$name = 'iii-dev-charts3';
#$key_value{'branch'} = 'main';
#$key_value{'helmVersion'} = '2.0';
#%key_value = {};
if ($is_offline eq 'offline') {
	$key_value{'url'} = $helm_catalog_url;
}
elsif ($iiidevops_ver eq 'develop') {
	$key_value{'url'} = 'https://raw.githubusercontent.com/iii-org/devops-charts-pack-and-index/develop/';
}
else {
	$key_value{'url'} = 'https://raw.githubusercontent.com/iii-org/devops-charts-pack-and-index/main/';
}
if (index($catalogs_name_list, '['.$name.']')<0) {
	$ret_msg = add_catalogs($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}


exit;

sub add_secrets {
	my ($p_name, %key_value) = @_;
	
	$json_file = $secrets_path.$p_name.'-secret.json';
	$tmpl_file = $json_file.'.tmpl';
	if (!-e $tmpl_file) {
		$ret_msg = "The template file [$tmpl_file] does not exist!";
		return($ret_msg);
	}
	
	$template = `cat $tmpl_file`;
	foreach $key (keys %key_value) {
		$template =~ s/{{$key}}/$key_value{$key}/g;
	}
	#print("-----\n$template\n-----\n\n");
	$api_msg = add_secrets_api($template);
	$ret_msg = "Create Secrets $json_file..$api_msg";
	
	return($ret_msg);
}

sub add_registry {
	my ($p_name, %key_value) = @_;

	$json_file = $secrets_path.$p_name.'-registry.json';
	$tmpl_file = $json_file.'.tmpl';
	if (!-e $tmpl_file) {
		$ret_msg = "The template file [$tmpl_file] does not exist!";
		return($ret_msg);
	}

	$template = `cat $tmpl_file`;
	foreach $key (keys %key_value) {
		$template =~ s/{{$key}}/$key_value{$key}/g;
	}
	#print("-----\n$template\n-----\n\n");
	$api_msg = add_registry_api($template);
	$ret_msg = "Create Registry $json_file..$api_msg";
	
	return($ret_msg);
}

sub add_catalogs {
	my ($p_name, %key_value) = @_;

	$json_file = $secrets_path.$p_name.'-catalogs.json';
	$tmpl_file = $json_file.'.tmpl';
	if (!-e $tmpl_file) {
		$ret_msg = "The template file [$tmpl_file] does not exist!";
		return($ret_msg);
	}

	$template = `cat $tmpl_file`;
	foreach $key (keys %key_value) {
		$template =~ s/{{$key}}/$key_value{$key}/g;
	}
	#print("-----\n$template\n-----\n\n");
	$api_msg = add_catalogs_api($template);
	$ret_msg = "Create Catalogs $json_file..$api_msg";
	
	return($ret_msg);
}

#curl --location --request POST 'http://10.20.0.68:31850/user/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "username": "super",
# "password": "IIIdevops123!"
#}'
sub get_api_key_api {
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/user/login' --header 'Content-Type: application/json' --data-raw '{
 "username": "$admin_init_login",
 "password": "$admin_init_password"
}'

END
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_key = $hash_msg->{'data'}->{'token'};
	}
	else {
		print("get api key Error : $message \n");
	}
	
	return;
}

#curl --location --request GET 'http://10.20.0.68:31850/maintenance/secretes_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk3NDc4NzEsIm5iZiI6MTYwOTc0Nzg3MSwianRpIjoiNDZmNTk2NjAtZDJhNy00ZWNlLTg3NmEtYTBlODg3MzE1NWI0IiwiZXhwIjoxNjEyMzM5ODcxLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.r1jdzklgHQufSCUTl2mODpsrt0Wh0ztaMwo2wYSgEas'
sub get_secrets_api {

	if ($api_key eq '') {
		get_api_key_api();
	}

	$cmd = <<END;
curl -s --location --request GET '$iiidevops_api/maintenance/secretes_into_rc_all' --header 'Authorization: Bearer $api_key'

END
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$hash_secrets = $hash_msg;
		$ret = @{ $hash_msg->{'data'} };
	}
	else {
		print("get secrets list Error : $message \n");
		$ret=-1;
	}
	
	return($ret);
}

#curl --location --request POST 'http://10.20.0.68:31850/maintenance/secretes_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk3NDc4NzEsIm5iZiI6MTYwOTc0Nzg3MSwianRpIjoiNDZmNTk2NjAtZDJhNy00ZWNlLTg3NmEtYTBlODg3MzE1NWI0IiwiZXhwIjoxNjEyMzM5ODcxLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.r1jdzklgHQufSCUTl2mODpsrt0Wh0ztaMwo2wYSgEas' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "name": "api-origin",
# "type": "secret",
# "data": {
#    "api-origin": "http://10.20.0.68:31850"
# }
#}'
sub add_secrets_api {
	my ($p_data) = @_;

	if ($api_key eq '') {
		get_api_key_api();
	}
	
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/maintenance/secretes_into_rc_all' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_key = $hash_ret->{'data'}->{'token'};
		$api_msg = 'OK!';
	}
	else {
		print("add sectets Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);
}

#curl --location --request GET 'http://10.20.0.72:31850/maintenance/registry_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub get_registry_api {

	if ($api_key eq '') {
		get_api_key_api();
	}

	$cmd = <<END;
curl -s --location --request GET '$iiidevops_api/maintenance/registry_into_rc_all' --header 'Authorization: Bearer $api_key'

END
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$hash_registry = $hash_msg;
		$ret = @{ $hash_msg->{'data'} };
	}
	else {
		print("get secrets list Error : $message \n");
		$ret=-1;
	}
	
	return($ret);
}

#curl --location --request POST 'http://10.20.0.72:31850/maintenance/registry_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "name": "harbor-local",
# "url": "10.20.0.71:5443",
# "username": "admin",
# "password": "MyPassword!"
#}'
sub add_registry_api {
	my ($p_data) = @_;

	if ($api_key eq '') {
		get_api_key_api();
	}
	
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/maintenance/registry_into_rc_all' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_msg = 'OK!';
	}
	else {
		print("add registry Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);	
}

#curl --location --request GET 'http://172.16.0.171:31850/rancher/catalogs' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MTIyNjc0OTMsIm5iZiI6MTYxMjI2NzQ5MywianRpIjoiM2FmNzFmMDYtYTUyZS00Mjk4LWIyM2EtMTZkNzhmM2YwYmZmIiwiZXhwIjoxNjE0ODU5NDkzLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzeXNhZG1pbiIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.t3RBUWkA-QC6gGPFb-1CqrAoLAMm75jjAwE0t2t4GeU'
sub get_catalogs_api {

	if ($api_key eq '') {
		get_api_key_api();
	}

	$cmd = <<END;
curl -s --location --request GET '$iiidevops_api/rancher/catalogs' --header 'Authorization: Bearer $api_key'

END
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$hash_catalogs = $hash_msg;
		$ret = @{ $hash_msg->{'data'} };
	}
	else {
		print("get catalogs list Error : $message \n");
		$ret=-1;
	}
	
	return($ret);
}

#curl --location --request POST 'http://172.16.0.171:31850/rancher/catalogs' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MTIyNjc0OTMsIm5iZiI6MTYxMjI2NzQ5MywianRpIjoiM2FmNzFmMDYtYTUyZS00Mjk4LWIyM2EtMTZkNzhmM2YwYmZmIiwiZXhwIjoxNjE0ODU5NDkzLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzeXNhZG1pbiIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.t3RBUWkA-QC6gGPFb-1CqrAoLAMm75jjAwE0t2t4GeU' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "name": "iii-dev-charts3",
# "branch": "main",
# "helmVersion": "2.0",
# "url": "https://github.com/iii-org/devops-charts/"
#}'
sub add_catalogs_api {
	my ($p_data) = @_;

	if ($api_key eq '') {
		get_api_key_api();
	}
	
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/rancher/catalogs' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_msg = 'OK!';
	}
	else {
		print("add catalogs Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);	
}


1;