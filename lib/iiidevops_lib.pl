#!/usr/bin/perl
# iiidevops lib
#
use JSON::MaybeXS qw(encode_json decode_json);

# GET /prod-api/system_git_commit_id HTTP/1.1
#curl --location -g --request GET 'http://10.20.0.85:31850/system_git_commit_id' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub get_iiidevops_ver {
	my ($v_cmd, $v_hash_msg, $v_message, $v_ret);
	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = "curl -s --location -g --request GET '$iiidevops_api/system_git_commit_id' --header 'Authorization: Bearer $g_api_key'";
	$v_hash_msg = decode_json(`$v_cmd`);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message ne 'success') {
		print("Get III DevOps ver Error : $v_message \n");
		$v_ret='';
	}
	else {
		# Before V1.6.0 the git_tag value is '' 
		$v_ret = $v_hash_msg->{'data'}->{'git_tag'};
	}

	return($v_ret);
}

#curl --location -g --request GET 'http://10.20.0.85:31850/maintenance/update_rc_pj_pipe_id?force=true' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub fix_pipeline_api {
	my ($v_cmd, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = "curl -s --location -g --request GET '$iiidevops_api/maintenance/update_rc_pj_pipe_id?force=true' --header 'Authorization: Bearer $g_api_key'";
	$v_hash_msg = decode_json(`$v_cmd`);
	$v_message = $v_hash_msg->{'message'};
	$v_ret=1;
	if ($v_message ne 'success') {
		print("Fix pipeline Error : $v_message \n");
		$v_ret=0;
	}
	
	return($v_ret);
}

# curl --location -g --request PUT 'http://10.20.0.85:31850/maintenance/update_pj_http_url' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub fix_gitlab_url {
	my ($v_cmd, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = "curl -s --location -g --request PUT '$iiidevops_api/maintenance/update_pj_http_url' --header 'Authorization: Bearer $g_api_key'";
	$v_hash_msg = decode_json(`$v_cmd`);
	$v_message = $v_hash_msg->{'message'};
	$v_ret=1;
	if ($v_message ne 'success') {
		print("Fix GitLab URL Error : $v_message \n");
		$v_ret=0;
	}
	
	return($v_ret);
}

#curl --location --request POST 'http://10.20.0.86:31850/user/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "username": "super",
# "password": "MyPassword"
#}'
sub get_api_key_api {
	my ($v_cmd, $v_hash_msg, $v_message);

	$v_cmd = <<END;
curl -s --location --request POST '$iiidevops_api/user/login' --header 'Content-Type: application/json' --data-raw '{
 "username": "$admin_init_login",
 "password": "$admin_init_password"
}'

END
	$v_hash_msg = decode_json(`$v_cmd`);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message eq 'success') {
		$g_api_key = $v_hash_msg->{'data'}->{'token'};
	}
	else {
		print("get api key Error : $v_message \n");
	}
	
	return;
}

1;