#!/usr/bin/perl
# Fix Pipeline after rehook (Rancher & Gitlab)
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

if ($gitlab_domain_name_tls eq '' || $gitlab_domain_name eq '') {
	print("The GitLab TLS [$gitlab_domain_name_tls] or GitLab domain [$gitlab_domain_name] is not set!\n");
	exit;
}

if (lc($ARGV[0]) ne 'force') {
	print("\nWARNING!!!\n You can only run the script after re-hooking the Rancher pipeline using GitLab. And you MUST input the argument 'Force' to execute the script. After the script is executed, the pipeline history data of all projects will be deleted!!!\n\n");
	exit;
}

$api_key = '';
if (fix_pipeline_api()) {
	print("Fix Pipeline OK!\n");
	if (fix_gitlab_url()) {
		print("Fix GitLab URL OK!\n");
	}
}

exit;

#curl --location -g --request GET 'http://10.20.0.85:31850/maintenance/update_rc_pj_pipe_id?force=true' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub fix_pipeline_api {
	local($cmd, $hash_msg, $message, $ret);

	if ($api_key eq '') {
		get_api_key_api();
	}

	$cmd = "curl -s --location -g --request GET '$iiidevops_api/maintenance/update_rc_pj_pipe_id?force=true' --header 'Authorization: Bearer $api_key'";
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	$ret=1;
	if ($message ne 'success') {
		print("Fix pipeline Error : $message \n");
		$ret=-1;
	}
	
	return($ret);
}

# curl --location -g --request PUT 'http://10.20.0.85:31850/maintenance/update_pj_http_url' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub fix_gitlab_url {
	local($cmd, $hash_msg, $message, $ret);

	if ($api_key eq '') {
		get_api_key_api();
	}

	$cmd = "curl -s --location -g --request PUT '$iiidevops_api/maintenance/update_pj_http_url' --header 'Authorization: Bearer $api_key'";
	$hash_msg = decode_json(`$cmd`);
	$message = $hash_msg->{'message'};
	$ret=1;
	if ($message ne 'success') {
		print("Fix GitLab URL Error : $message \n");
		$ret=-1;
	}
	
	return($ret);
}

#curl --location --request POST 'http://10.20.0.68:31850/user/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "username": "super",
# "password": "MyPassword"
#}'
sub get_api_key_api {
	local($cmd, $hash_msg, $message);

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

1;