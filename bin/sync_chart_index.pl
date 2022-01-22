#!/usr/bin/perl
# Add Secrets & Registry & Catalogs for all Rancher Projects
#
use FindBin qw($Bin);
use MIME::Base64;
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");

$is_update = defined($ARGV[0])?lc($ARGV[0]):''; # 'gitlab_update' or 'gitlab_offline' 'gitlab_offline_update' : run catalog url to gitlab
$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$g_secrets_path = "$Bin/../devops-api/secrets/";

# Get API login token
$login_cmd = "curl -s -H \"Content-Type: application/json\" --request POST '$iiidevops_api/user/login' --data-raw '{\"username\": \"$admin_init_login\",\"password\": \"$admin_init_password\"}'";
$api_token = decode_json(`$login_cmd`)->{'data'}->{'token'};
$sed_alert_cmd = "curl -s -H \"Content-Type: application/json\" -H \"Authorization: Bearer $api_token\" --request POST '$iiidevops_api/alert_message'";

#-----
# Add Apps Catalogs
#-----
print("\nAdd Apps Catalogs\n-----\n");
# Get catalogs List
$hash_catalogs = {};
$catalogs_num = get_catalogs_api();
$catalogs_name_list = '';
$helm_catalog_group = 'iiidevops-catalog';
$helm_catalog = 'devops-charts-pack-and-index';
$helm_catalog_url = '';
foreach $item (@{ $hash_catalogs->{'data'} }) {
	$catalogs_name_list .= "[$item->{'name'}]";
}

$gitlab_domain_name = get_domain_name('gitlab');
$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';

# Check if the GitLab group $helm_catalog_group (iiidevops-templates) exists
# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/
#$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/groups/";
log_print("Get GitLab group list..\n");
$cmd_msg = call_gitlab_api('GET', 'groups');
$hash_msg = decode_json($cmd_msg);
$group_list = '';
$helm_catalog_group_id = '';
foreach $group_hash (@ {$hash_msg}) {
	if ($group_hash->{'name'} eq $helm_catalog_group) {
		if ($is_update eq 'gitlab_update' || $is_update eq 'gitlab_offline_update') {
			if ($is_update eq 'gitlab_update') {
				$github_user_token = $sync_templ_key;
				if (index($github_user_token, ":")<=0) {
					print("github_token:[$github_user_token] is worng!\n");
					exit;
				} else {
					$token_ck_cmd = "curl -s -u $github_user_token https://api.github.com/user";
					$token_msg = `$token_ck_cmd`;
					if(index($token_msg,"node_id")<0) {
						print("github_token:[$github_user_token] is worng!\n");
						exit;
					} elsif ($iiidevops_ver ne 'develop') {
						$g_github_repo_cmd = "curl -s -u $github_user_token -H \"Accept: application/vnd.github.inertia-preview+json\" https://api.github.com/repos/iii-org/devops-charts-pack-and-index";
						$repo_hash = decode_json(`$g_github_repo_cmd`);
						$repo_max_time = ($repo_hash->{'created_at'} gt $repo_hash->{'updated_at'})?$repo_hash->{'created_at'}:$repo_hash->{'updated_at'};
						$repo_max_time = ($repo_max_time gt $repo_hash->{'pushed_at'})?$repo_max_time:$repo_hash->{'pushed_at'};
						
						# Check if the GitLab group $helm_catalog_group (iiidevops-templates) exists
						# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/
						#$cmd = "$v_cmd -k -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/projects?search=devops-charts-pack-and-index";
						$cmd_msg = call_gitlab_api('GET', 'projects?search=devops-charts-pack-and-index');
						$gitlab_prj_created_at = decode_json($cmd_msg)->[0]->{'created_at'};
						if ($repo_max_time le $gitlab_prj_created_at) {
							print("GitLab repo [$helm_catalog] ($repo_max_time) is latest\n");
							exit;
						}
					}
					else {
						print("Always update the GitLab repo [$helm_catalog] in the development environment!\n");
					}
				}
			}
			$helm_catalog_group_id = $group_hash->{'id'};
			$ret = delete_gitlab_group($helm_catalog_group_id);
			if ($ret<0) {
				log_print("Delete GitLab group [$helm_catalog_group] Error!\n---\n$cmd_msg\n---\n");
				$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
				$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
				$sed_alert = `$sed_cmd`;
				exit;
			}

			log_print("Delete GitLab group [$helm_catalog_group] OK!\n\n");
		}else {
			$group_list .= '['.$group_hash->{'name'}.']';
		}
	}
}

# Check if the GitLab project $helm_catalog  exists
#$cmd = "$v_cmd -k -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/projects?search=devops-charts-pack-and-index";
$cmd_msg = call_gitlab_api('GET', 'projects?search=devops-charts-pack-and-index');
$hash_msg = decode_json($cmd_msg);
foreach $catalogs_hash (@ {$hash_msg}) {
	if ($catalogs_hash->{'name'} eq $helm_catalog) {
		if ($is_update eq 'gitlab_update' || $is_update eq 'gitlab_offline_update') {
			$helm_catalog_id = $catalogs_hash->{'id'};
			$ret = delete_gitlab($helm_catalog_id);
			if ($ret<0) {
				log_print("Delete GitLab Project catalog [$helm_catalog_group] Error!\n---\n$cmd_msg\n---\n");
				$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
				$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
				$sed_alert = `$sed_cmd`;
				exit;
			}
			log_print("Delete GitLab Project catalog [$helm_catalog_group] OK!\n\n");
		}
	}
}

if ($group_list eq '') {
	log_print("group_list :[]\n");
}
else {
	log_print("group_list : $group_list\n");
}
# Create $helm_catalog_group group
if (index($group_list, "[$helm_catalog_group]")<0) {
	$ret = create_gitlab_group($helm_catalog_group);
	if ($ret<0) {
		log_print("Add GitLab group [$helm_catalog_group] Error!\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
		$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
		$sed_alert = `$sed_cmd`;
		exit;
	}
	log_print("Add GitLab group [$helm_catalog_group] OK!\n\n");
	$helm_catalog_group_id = $ret;
}
else {
	log_print("GitLab group [$helm_catalog_group] exists!\n\n");
}

my $p_tar = "$Bin/$helm_catalog.tar.gz";
if (!-e $p_tar) {
	print("The file [$p_tar] does not exist!\n");
	exit; 
}

##############
# Get GitLab Group $helm_catalog_group (iiidevops-templates) project list
# Ref - https://docs.gitlab.com/ee/api/groups.html 
#	By default, this request returns 20 results at a time because the API results are paginated.
#	https://docs.gitlab.com/ee/api/README.html#pagination
# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/iiidevops-templates/projects?per_page=100
#$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://localhost:32080/api/v4/groups/$helm_catalog_group/projects?per_page=100";
log_print("Get GitLab group $helm_catalog_group project list..\n");
$cmd_msg = call_gitlab_api('GET', "groups/$helm_catalog_group/projects?per_page=100");
if (index($cmd_msg, '"message"')>=0) {
	log_print("Get GitLab group [$helm_catalog_group] projects Error!\n---\n$cmd_msg\n---\n");
	$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
	$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
	$sed_alert = `$sed_cmd`;
	exit;
}

$hash_gitlab_project = decode_json($cmd_msg);
$prj_name_list = '';
foreach $project_hash (@ {$hash_gitlab_project}) {
	if ($project_hash->{'name'} eq $helm_catalog) {
		$helm_catalog_group_id = $project_hash->{'id'};
		$helm_catalog_url = $project_hash->{'web_url'};
	}
	$prj_name_list .= '['.$project_hash->{'name'}.']';
}
if ($prj_name_list eq '') {
	log_print("prj_name_list :[]\n");
}
else {
	log_print("prj_name_list : $prj_name_list\n");
}

if ($is_update ne 'gitlab_offline' && $is_update ne 'gitlab_offline_update') {
	$github_user_token = $sync_templ_key;
	if (index($github_user_token, ":")<=0) {
		print("github_token:[$github_user_token] is worng!\n");
		exit;
	} else {
		$token_ck_cmd = "curl -s -u $github_user_token https://api.github.com/user";
		$token_msg = `$token_ck_cmd`;
		if(index($token_msg,"node_id")<0) {
			print("github_token:[$github_user_token] is worng!\n");
			exit;
		}
	}
	# curl -H "Accept: application/vnd.github.inertia-preview+json" https://api.github.com/orgs/iiidevops-templates/repos
	$arg_str = ($github_user_token ne '')?"-u $github_user_token ":'';
	$cmd = "curl -s $arg_str -H \"Accept: application/vnd.github.inertia-preview+json\" https://api.github.com/repos/iii-org/devops-charts-pack-and-index";
	log_print("Get GitHub repo [devops-charts-pack-and-index] data..\n");
	$cmd_msg = `$cmd`;
	if (index($cmd_msg, 'node_id')<0) {
		log_print("Get GitHub org [devops-charts-pack-and-index] repos Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
		$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
		$sed_alert = `$sed_cmd`;
		exit;
	}
	$hash_github_repo = decode_json($cmd_msg);
	$github_prj_name = $hash_github_repo->{'name'};
	$github_prj_id = $hash_github_repo->{'id'};
}

if (index($prj_name_list, "[$helm_catalog]")<0) {
	if ($is_update eq 'gitlab_offline' || $is_update eq 'gitlab_offline_update') {
		$ret = create_gitlab_group_project($helm_catalog,$helm_catalog_group_id);
		if ($ret<0) {
			log_print("Add GitLab group [$helm_catalog_group] project [$helm_catalog] Error!\n---\n$cmd_msg\n---\n");
			$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
			$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
			$sed_alert = `$sed_cmd`;
			exit;
		}
		log_print("Add GitLab group [$helm_catalog_group] project [$helm_catalog] OK!\n\n");
		if (index($ret, $helm_catalog)>=0){
			$hash_msg = decode_json($ret);
			$prj_name = $hash_msg->{'name'};
			$helm_catalog_url = $hash_msg->{'web_url'};
			$git_url = $hash_msg->{'http_url_to_repo'};
			log_print("Create $prj_name Success\n");
			# push Helm Catalog Project to GitLab
			system("echo $v_http://\"root\":\"$gitlab_root_passwd\"\@$gitlab_domain_name > ~/.git-credentials");
			system("git config --global credential.$v_http://$gitlab_domain_name.username root");
			system("git config --global credential.$v_http://$gitlab_domain_name.password $gitlab_root_passwd");
			system("git config --global credential.helper store");
			chdir "$Bin";
			$tar_msg = `tar zxvf $Bin/$helm_catalog.tar.gz`;
			chdir "$Bin/$helm_catalog";
			$git_msg = `git remote rename origin old-origin; git remote add origin $git_url; git push -u origin --all; git push -u origin --tags`;
			chdir "$Bin";
			$rm_tar_msg = `rm -rf $Bin/$helm_catalog`;
			log_print("Add Gitlab Helm Catalog [$helm_catalog] templates OK\n");
		}
	}
	else {
		$ret = import_github($github_prj_id, $github_prj_name, $helm_catalog_group_id);
		if ($ret<0) {
			log_print("Add GitLab group [$helm_catalog_group] project [$helm_catalog] Error!\n---\n$cmd_msg\n---\n");
			$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg},\"alert_code\":20004}";
			$sed_cmd = "$sed_alert_cmd --data-raw '$error_msg'";
			$sed_alert = `$sed_cmd`;
			exit;
		}
		else {
			log_print("Add Gitlab Helm Catalog [$helm_catalog] templates OK\n");
			$hash_msg = decode_json($ret);
			$helm_catalog_url = $hash_msg->{'web_url'};
		}
	}
}
else {
	log_print("GitLab group[$helm_catalog_group] project[$helm_catalog] exists!\n\n");
}

# iii-dev-charts3
$name = 'iii-dev-charts3';
if ($iiidevops_ver eq 'develop') {
	$key_value{'url'} = $helm_catalog_url."/raw/develop";
	$key_value{'branch'} = "develop";
}
else {
	$key_value{'url'} = $helm_catalog_url."/raw/main";
	$key_value{'branch'} = "main";
}

if (index($catalogs_name_list, '['.$name.']')<0) {
	$ret_msg = add_catalogs($name, %key_value);
	log_print("$name : $ret_msg\n");
}
else {
	if($is_update eq 'gitlab_update' || $is_update eq 'gitlab_offline_update') {
		$ret_msg = update_catalogs_api($name, %key_value);
		$cmd_msg = `kubectl rollout restart deployment rancher -n cattle-system`;
		log_print("Update catalog");
		# check deploy status
		$isChk=1;
		while($isChk) {
			sleep($isChk);
			$isChk = 0;
			foreach $line (split(/\n/, `kubectl get deployment -n cattle-system | grep rancher`)) {
				$line =~ s/( )+/ /g;
				($l_name, $l_ready, $l_update, $l_available, $l_age) = split(/ /, $line);
				($l_ready_pod, $l_replica_pod) = split("/", $l_ready);
				if ($l_replica_pod ne $l_update || $l_replica_pod ne $l_available) {
					log_print("...");
					$isChk = 3;
				} 
			}
		}
		log_print("\nUpdate catalog [$name] OK]\n");
	}
	else {
		print("$name : already exists, Skip!\n");
	}
}

exit;