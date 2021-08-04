#!/usr/bin/perl
# iiidevops lib
#
use JSON::MaybeXS qw(encode_json decode_json);

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
	
	if ($p_type eq 'raw') {
		return($v_hash_msg);
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