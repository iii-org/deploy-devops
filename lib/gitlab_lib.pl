#!/usr/bin/perl
# GitLab lib
#

sub create_gitlab_group {
	my ($p_gitlab_groupname) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg, $v_data);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X POST -d '{"name": "iiidevops-templates","path": "iiidevops-templates"}' https://gitlab-demo.iiidevops.org/api/v4/groups/
	#$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$p_gitlab_groupname\",\"path\": \"$p_gitlab_groupname\"}' $v_http://localhost:32080/api/v4/groups/";
	$v_data=<<END;
{
	"name": "$p_gitlab_groupname", 
	"path": "$p_gitlab_groupname",
	"visibility":"public"
}
END
	$cmd_msg = call_gitlab_api('POST', 'groups', $v_data, 'application/json');
	$ret = '';
	if (index($cmd_msg, $p_gitlab_groupname)>=0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'name'};
		#print("[$ret]\n");
	}
	if ($ret eq '' || $ret ne $p_gitlab_groupname){
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}

	return($hash_msg->{'id'});
}

sub delete_gitlab_group {
	my ($p_gitlab_groupid) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X DELETE  https://gitlab-demo.iiidevops.org/api/v4/groups/12
	#$cmd = "$v_cmd -s -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X DELETE  $v_http://localhost:32080/api/v4/groups/$p_gitlab_groupid";
    $cmd_msg = call_gitlab_api('DELETE', "groups/$p_gitlab_groupid");
    if (index($cmd_msg, "Accepted")>=0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'id'};
	}else{
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}
	sleep(5);
	return($p_gitlab_groupid);
}

sub update_github {
	my ($p_gitlab_id, $p_repo_id, $p_new_name, $p_target_namespace) = @_;
	my ($cmd, $cmd_msg);

	delete_gitlab($p_gitlab_id);
	import_github($p_repo_id, $p_new_name, $p_target_namespace);

	return;
}

sub create_gitlab_group_project {
	my ($project_name, $namespace_id) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg, $v_data);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X POST -d '{"name": "iiidevops-templates","path": "iiidevops-templates"}' https://gitlab-demo.iiidevops.org/api/v4/groups/
	#$cmd = "$v_cmd -s --request POST --header \"PRIVATE-TOKEN: $gitlab_private_token\" --data \"name=$project_name&namespace_id=$namespace_id\" $v_http://localhost:32080/api/v4/projects/";
	#$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$project_name\",\"namespace_id\": \"$namespace_id\"}' $v_http://localhost:32080/api/v4/projects/";
	$v_data=<<END;
{
	"name": "$project_name", 
	"namespace_id": "$namespace_id",
	"visibility":"public"
}
END
	$cmd_msg = call_gitlab_api('POST', 'projects', $v_data, 'application/json');

	$ret = '';
	if (index($cmd_msg, $project_name)>=0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'name'};
		print("[$ret]\n");
	}
	if ($ret eq '' || $ret ne $project_name){
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}

	return($cmd_msg);
}

sub delete_gitlab {
	my ($p_gitlab_id) = @_;
	my ($cmd, $cmd_msg);

	#curl --request DELETE --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/projects/2
	#$cmd = "$v_cmd -s --request DELETE --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/projects/$p_gitlab_id";
	$cmd_msg = call_gitlab_api('DELETE', "projects/$p_gitlab_id");
	if (index($cmd_msg, 'Accepted')<0) {
		log_print("delete_gitlab [$p_gitlab_id] Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
		sed_alert_msg($error_msg);
		exit;
	}
	sleep(5);

	return;
}

sub import_github {
	my ($p_repo_id, $p_new_name, $p_target_namespace) = @_;
	my ($cmd, $cmd_msg, $arg_user, $hash_msg, $id, $import_status, $v_name);

	$github_token = substr($github_user_token, rindex($github_user_token,":")+1);
	#$cmd = "$v_cmd -s --request POST --header \"PRIVATE-TOKEN: $gitlab_private_token\" --data \"personal_access_token=$github_token&repo_id=$p_repo_id&new_name=$p_new_name&target_namespace=iiidevops-catalog  \" $v_http://localhost:32080/api/v4/import/github";
	$cmd_msg = call_gitlab_api('POST', "import/github", "personal_access_token=$github_token&repo_id=$p_repo_id&new_name=$p_new_name&target_namespace=$p_target_namespace");
	if (index($cmd_msg, $p_new_name)<0) {
		log_print("import_github [$p_new_name] Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
		sed_alert_msg($error_msg);
		exit;
	}

	$hash_gitlab_repo = decode_json($cmd_msg);
	$repo_id = $hash_gitlab_repo->{'id'};
	# Ref - https://docs.gitlab.com/ee/api/project_import_export.html
	# curl --header "PRIVATE-TOKEN: <your_access_token>" "https://gitlab.example.com/api/v4/projects/1/import"
	#$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/projects/$repo_id/import";
	$import_status = '';
	while ($import_status ne 'failed' && $import_status ne 'finished') {
		$cmd_msg = call_gitlab_api('GET', "projects/$repo_id/import");
		if (index($cmd_msg, $p_new_name)<0) {
			$import_status = 'failed';
		}
		else {
			$hash_msg = decode_json($cmd_msg);
			$import_status = $hash_msg->{'import_status'};
			sleep(1);
		}
	}
	if ($import_status eq 'failed') {
		log_print("Import failed! [$cmd_msg]\n");
		exit;
	}

	# iiidevops-catalog group already exist, only import chart_idx project
	if ($p_target_namespace eq '') {
		$cmd_msg = call_gitlab_api('GET', "projects/$repo_id");
		$hash_msg = decode_json($cmd_msg);
		return($hash_msg->{'web_url'});
	}
	elsif ($p_target_namespace ne 'iiidevops-catalog') {
		exit;
	}
	
	# target_namespace : iiidevops-catalog group
	$cmd_msg = call_gitlab_api('GET', "/groups/$p_target_namespace");
	$hash_msg = decode_json($cmd_msg);
	$v_name = $hash_msg->{'name'};
	if ($v_name eq 'iiidevops-catalog') {
		return($hash_msg->{'projects'}[0]->{'web_url'});
	}
	
	# transfer import project to target_namespace
	#$cmd = "$v_cmd -s --request PUT --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/projects/$repo_id/transfer?namespace=$p_target_namespace";
	$cmd_msg = call_gitlab_api('PUT', "projects/$repo_id/transfer?namespace=$p_target_namespace");
	if (index($cmd_msg, $p_new_name)<0) {
		log_print("import_github [$p_new_name] Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
		sed_alert_msg($error_msg);
		exit;
	}

	return($cmd_msg);
}

sub update_gitlab_user_password {
	my ($p_gl_username,$p_gl_passwd) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	#$cmd = "$v_cmd -s -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X PUT -d '{"password": "xxxx"}' $v_http://localhost:32080/api/v4/users/$user_id";
    $gl_user = decode_json(call_gitlab_api('GET', "/users?username=$p_gl_username"));
	$gl_user_id = @{$gl_user}[0]->{'id'};
	$update_user_passwd = call_gitlab_api('PUT', "/users/$gl_user_id", "{\"password\": \"$p_gl_passwd\"}", 'application/json');
	
	if (index($update_user_passwd, $p_gl_username)<0) {
		return(false);
	}
	return(ture);
}
1;