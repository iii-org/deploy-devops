#!/usr/bin/perl
# iiidevops lib
#
use JSON::MaybeXS qw(encode_json decode_json);

# Get Version Center deployment_uuid setting information
#curl --location --request POST '$p_vc_url/login?uuid=$p_uuid'
#curl --location --request GET '$p_vc_url/current_version' --header 'Authorization: Bearer eyJ0kZXZvcHMuaWNoaWF5aS5jb20ifQ.jsTn6DOu7JP5Iqg-8lUhjYsDySi0aexGjm6DiusvN0M'
#
sub get_version_center_info {
	my ($p_vc_url, $p_uuid) = @_;
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret, $v_auth, $v_deploy_version, $v_api_tag, $v_ui_tag);
	
	# Login in version center
	if ($p_vc_url eq '' || $p_uuid eq '') {
		print("Version Center URL [$p_vc_url] or UUID [$p_uuid] Error!\n");
		return(('Err0', '', ''));
	}
	$v_cmd = "curl -s --location -g --request POST '$p_vc_url/login?uuid=$p_uuid'";
	$v_cmd_msg = `$v_cmd`;
	if ($v_cmd_msg eq '') {
		print("Call Version Center API Error![$v_cmd]\n");
		return(('Err1', '', ''));
	}
	
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message ne 'success') {
		print("Login Version Center Error : $v_cmd_msg \n");
		return(('Err2', '', ''));
	}
	$v_auth = $v_hash_msg->{'data'}->{'access_token'};
	if ($v_auth eq '') {
		print("access_token Error!\n");
		return(('Err3', '', ''));
	}
	
	# Get setting info
	$v_cmd = "curl -s --location -g --request GET '$p_vc_url/current_version' --header 'Authorization: Bearer $v_auth'";
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message ne 'success') {
		print("Get setting info Error : $v_cmd_msg \n");
		return(('Err4', '', ''));
	}
	$v_deploy_version = $v_hash_msg->{'data'}->{'version_name'}; # "V1.10.1"
	$v_api_tag = $v_hash_msg->{'data'}->{'api_image_tag'}; # "1.10.1"
	$v_ui_tag = $v_hash_msg->{'data'}->{'ui_image_tag'}; # "1.10.1"

	return(($v_deploy_version, $v_api_tag, $v_ui_tag));
}

# Get nexus info
# api_version | deploy_version |           deployment_uuid            
#-------------+----------------+--------------------------------------
# 1.8.0.2     | develop        | 37102316-e2af-11eb-9e25-e265b97a391f
sub get_nexus_info {
	my ($p_key) = @_;
	my ($v_sql, $v_cmd, $v_cmd_msg, @arr_line, $t_line, $v_api_version, $v_deploy_version, $v_deployment_uuid);

	$v_sql = "select api_version, deploy_version, deployment_uuid from nexus_version where id=1";
	$v_cmd = "psql -d 'postgresql://postgres:$db_passwd\@$db_ip:31403/devopsdb' -c \"$v_sql\"";
	$v_cmd_msg = `$v_cmd 2>&1`;
	@arr_line = split(/\n/, $v_cmd_msg);
	if (index($arr_line[0], 'deploy_version')<0) {
		$v_cmd_msg =~ s/\n|\r//g;
		print("Err:[$v_cmd_msg]\n");
		return("Err1");
	}
	$t_line=$arr_line[2];
	$t_line =~ s/ //g;
	($v_api_version, $v_deploy_version, $v_deployment_uuid)=split(/\|/, $t_line);
	#print("[$v_api_version], [$v_deploy_version], [$v_deployment_uuid]\n");
	if (lc($p_key) eq 'api_version') {
		return($v_api_version);
	}
	if (lc($p_key) eq 'deploy_version') {
		return($v_deploy_version);
	}
	if (lc($p_key) eq 'deployment_uuid') {
		return($v_deployment_uuid);
	}
	return("Err2");
}

# p_value Exp. develop / V1.7.1
sub set_nexus_deploy_version {
	my ($p_value) = @_;
	my ($v_sql, $v_cmd, $v_cmd_msg, @arr_line, $t_line, $v_api_version, $v_deploy_version, $v_deployment_uuid);

	if ($p_value ne 'develop' && substr($p_value,0,1) ne 'V') {
		print("Check version [$p_value] format error!\n");
		return('Err1');
	}
	
	$v_sql = "update nexus_version set deploy_version='$p_value' where id=1";
	$v_cmd = "psql -d 'postgresql://postgres:$db_passwd\@$db_ip:31403/devopsdb' -c \"$v_sql\"";
	$v_cmd_msg = `$v_cmd 2>&1`;
	if (index($v_cmd_msg, 'UPDATE 1')<0) {
		print("Err:[$v_cmd_msg]\n");
		return('Err2');
	}

	return($p_value);
}

# GET /prod-api/system_git_commit_id HTTP/1.1
#curl --location -g --request GET 'http://10.20.0.85:31850/system_git_commit_id' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub get_iiidevops_ver {
	my ($p_type) = @_;
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret);
	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = "curl -s --location -g --request GET '$iiidevops_api/system_git_commit_id' --header 'Authorization: Bearer $g_api_key'";
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message ne 'success') {
		print("Get III DevOps ver Error : $v_message \n");
		$v_ret='';
	}
	else {
		# Before V1.6.0 the git_tag value is '' 
		$v_ret = $v_hash_msg->{'data'}->{'git_tag'};
	}
	
	if ($p_type eq 'raw') {
		return($v_cmd_msg);
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

#curl --location --request GET 'http://10.20.0.72:31850/maintenance/registry_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
sub get_registry_api {
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = <<END;
curl -s --location --request GET '$iiidevops_api/maintenance/registry_into_rc_all' --header 'Authorization: Bearer $g_api_key'

END
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message eq 'success') {
		$g_hash_registry = $v_hash_msg;
		$v_ret = @{ $v_hash_msg->{'data'} };
	}
	else {
		print("get secrets list Error : $v_cmd_msg \n");
		$v_ret=-1;
	}
	
	return($v_ret);
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
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}
	
	$v_cmd = <<END;
curl -s --location --request POST '$iiidevops_api/maintenance/registry_into_rc_all' --header 'Authorization: Bearer $g_api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message eq 'success') {
		$v_ret = 'OK!';
	}
	else {
		print("add registry Error:\n$v_cmd_msg\n");
		$v_ret = 'Failed!';
	}
	
	return($v_ret);	
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
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}
	
	$v_cmd = <<END;
curl -s --location --request POST '$iiidevops_api/maintenance/secretes_into_rc_all' --header 'Authorization: Bearer $g_api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message eq 'success') {
		$v_ret = 'OK!';
	}
	else {
		print("add sectets Error:\n$v_cmd_msg\n");
		$v_ret = 'Failed!';
	}
	
	return($v_ret);
}

#curl --location --request GET 'http://10.20.0.68:31850/maintenance/secretes_into_rc_all' \
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk3NDc4NzEsIm5iZiI6MTYwOTc0Nzg3MSwianRpIjoiNDZmNTk2NjAtZDJhNy00ZWNlLTg3NmEtYTBlODg3MzE1NWI0IiwiZXhwIjoxNjEyMzM5ODcxLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.r1jdzklgHQufSCUTl2mODpsrt0Wh0ztaMwo2wYSgEas'
sub get_secrets_api {
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message, $v_ret);

	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = <<END;
curl -s --location --request GET '$iiidevops_api/maintenance/secretes_into_rc_all' --header 'Authorization: Bearer $g_api_key'

END
	$v_cmd_msg = `$v_cmd`;
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_message = $v_hash_msg->{'message'};
	if ($v_message eq 'success') {
		$g_hash_secrets = $v_hash_msg;
		$ret = @{ $v_hash_msg->{'data'} };
	}
	else {
		print("get secrets list Error : $v_cmd_msg \n");
		$ret=-1;
	}
	
	return($ret);
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

#curl --location --request GET http://localhost:31850/monitoring/rancher/default_name
#--header 'Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpYXQiOjE2MDk4MjYyNjAsIm5iZiI6MTYwOTgyNjI2MCwianRpIjoiYjY1MTkyNzEtZjYyNi00NTQ5LWIzNzUtYWY3NWQ3ZTQxMzQwIiwiZXhwIjoxNjEyNDE4MjYwLCJpZGVudGl0eSI6eyJ1c2VyX2lkIjoxLCJ1c2VyX2FjY291bnQiOiJzdXBlciIsInJvbGVfaWQiOjUsInJvbGVfbmFtZSI6IkFkbWluaXN0cmF0b3IifSwiZnJlc2giOmZhbHNlLCJ0eXBlIjoiYWNjZXNzIn0.p1VlT_JME_azSuQ59dwwmJOGkGxW34yPa4CeNvgp4JE'
#{"default_cluster_name": true}
# Check Rancher Cluster Name is iiidevops-k8s
sub is_rancher_default_name_ok {
	my ($v_cmd, $v_cmd_msg, $v_hash_msg, $v_message);

	if ($g_api_key eq '') {
		get_api_key_api();
	}

	$v_cmd = "curl -s --location --request GET 'http://localhost:31850/monitoring/rancher/default_name' --header 'Authorization: Bearer $g_api_key'";
	$v_cmd_msg = `$v_cmd`;
	if ($v_cmd_msg ne '') {
		$v_hash_msg = decode_json($v_cmd_msg);
		$v_message = $v_hash_msg->{'default_cluster_name'};
	}
	return($v_message eq 'true');
}

1;