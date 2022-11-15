#!/usr/bin/perl
# sync project template script
#
# Usage: sync-prj-templ.pl [github_id:github_token] [github_org (iiidevops-templates)] [force-sync]
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

if (!defined($ARGV[0])) {
	if ( $sync_templ_key eq '' ) {
		print("Usage: $prgname [github_id:github_token] [github_org] [force-sync]\n");
		print("OR Setting ~/deploy-devops/bin/generate_env.pl sync_templ_key [github_id:github_token]\n");
		exit(1);
	}
	else {
		$github_user_token = (defined($ARGV[0]))?$ARGV[0]:$sync_templ_key;
	}
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");

($cmd_msg, $github_token) = split(':', $github_user_token);
if (length($github_token)!=40) {
	print("github_token:[$github_token] is worng!\n");
	sed_alert_msg("github_token is worng");
	exit(1);
}

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$github_org = (defined($ARGV[1]))?$ARGV[1]:'iiidevops-templates';
$local_group = 'local-templates';
$force_sync = (defined($ARGV[2]) && lc($ARGV[2]) eq 'force-sync');

# Get GitHub org $github_org (iiidevops-templates) repo list
# curl -H "Accept: application/vnd.github.inertia-preview+json" https://api.github.com/orgs/iiidevops-templates/repos?per_page=100
$arg_str = ($github_user_token ne '')?"-u $github_user_token ":'';
$cmd = "curl -s $arg_str -H \"Accept: application/vnd.github.inertia-preview+json\" https://api.github.com/orgs/$github_org/repos?per_page=100";
log_print("Get GitHub org $github_org repo list..\n");
$cmd_msg = `$cmd`;
if (index($cmd_msg, 'node_id')<0) {
	log_print("Get GitHub org [$github_org] repos Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
	$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
	sed_alert_msg($error_msg);
	exit(1);
}
$hash_github_repo = decode_json($cmd_msg);
$repo_num=0;
$repo_name_list = '';
foreach $repo_hash (@ {$hash_github_repo}) {
	$repo_num++;
	$repo_name = $repo_hash->{'name'};
	$repo_name_list .= '['.$repo_name.']';
	log_print("[$repo_num]:$repo_name\n");
}
log_print("GitHub org [$github_org] : $repo_num repo(s)\n\n");
if ($repo_num==0){
	exit;
}

# Check if the GitLab group $github_org (iiidevops-templates) exists
# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/
log_print("Get GitLab group list..\n");
$cmd_msg = call_gitlab_api('GET', 'groups');
$hash_msg = decode_json($cmd_msg);
$group_list = '';
foreach $group_hash (@ {$hash_msg}) {
	$group_list .= '['.$group_hash->{'name'}.']';
}
if ($group_list eq '') {
	log_print("---\n$cmd_msg\n---\n");
}
else {
	log_print("group_list : $group_list\n");
}

# Create $github_org group
if (index($group_list, "[$github_org]")<0) {
	$ret = create_gitlab_group($github_org);
	if ($ret<0) {
		log_print("Add GitLab group [$github_org] Error!\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
		sed_alert_msg($error_msg);
		exit(1);
	}
	log_print("Add GitLab group [$github_org] OK!\n\n");
}
else {
	log_print("GitLab group [$github_org] exists!\n\n");
}

# Create local-templates group
if (index($group_list, "[$local_group]")<0) {
	$ret = create_gitlab_group($local_group);
	if ($ret<0) {
		log_print("Add GitLab group [$local_group] Error!\n---\n$cmd_msg\n---\n");
		$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
		sed_alert_msg($error_msg);
		exit(1);
	}
	log_print("Add GitLab group [$local_group] OK!\n\n");
}
else {
	log_print("GitLab group [$local_group] exists!\n\n");
}


# Get GitLab Group $github_org (iiidevops-templates) project list
# Ref - https://docs.gitlab.com/ee/api/groups.html 
#	By default, this request returns 20 results at a time because the API results are paginated.
#	https://docs.gitlab.com/ee/api/README.html#pagination
# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/iiidevops-templates/projects?per_page=100
log_print("Get GitLab group $github_org project list..\n");
$cmd_msg = call_gitlab_api('GET', "groups/$github_org/projects?per_page=100");
if (index($cmd_msg, '"message"')>=0) {
	log_print("Get GitLab group [$github_org] projects Error!\n---\n$cmd_msg\n---\n");
	$error_msg = "{\"message\":\"deploy-devops perl error\",\"resource_type\":\"github\",\"detail\":{\"perl\":\"$Bin/$prgname\",\"msg\":$cmd_msg}}";
	sed_alert_msg($error_msg);
	exit(1);
}

$hash_gitlab_project = decode_json($cmd_msg);
$project_num=0;
$prj_name_list = '';
%hash_prj_id={};
%hash_prj_path={};
%hash_prj_created_at={};
foreach $project_hash (@ {$hash_gitlab_project}) {
	$prj_name = $project_hash->{'name'};
	$prj_id = $project_hash->{'id'};
	if (index($repo_name_list, "[$prj_name]")<0) {
		delete_gitlab($prj_id);
		log_print("**Remove**:[$prj_id] $prj_name OK!\n");
	}
	else {
		$project_num++;
		$prj_name_list .= '['.$prj_name.']';
		$hash_prj_id{$prj_name}=$prj_id;
		$hash_prj_path{$prj_name}=$project_hash->{'path'};
		$hash_prj_created_at{$prj_name}=$project_hash->{'created_at'};
		log_print("[$project_num]:".$project_hash->{'name'}."\n");
	}
}
log_print("Gitlab group [$github_org] : $project_num project(s)\n\n");


# Sync GitHub org -> GitLab group
log_print("Sync GitHub org [$github_org] -> GitLab group [$github_org]..\n");
$idx=0;
$isUpdate=0;
foreach $repo_hash (@ {$hash_github_repo}) {
	$idx++;
	$repo_id = $repo_hash->{'id'};
	$repo_name = $repo_hash->{'name'};
	$repo_max_time = ($repo_hash->{'created_at'} gt $repo_hash->{'updated_at'})?$repo_hash->{'created_at'}:$repo_hash->{'updated_at'};
	$repo_max_time = ($repo_max_time gt $repo_hash->{'pushed_at'})?$repo_max_time:$repo_hash->{'pushed_at'};
	log_print("[$idx].	name:".$repo_name." ($repo_max_time)\n");
	if (index($prj_name_list, "[$repo_name]")>=0) {
		log_print("	GitLab-> id:".$hash_prj_id{$repo_name}." path:".$hash_prj_path{$repo_name}." created_at:".$hash_prj_created_at{$repo_name}."\n");
		if ($force_sync || ($repo_max_time gt $hash_prj_created_at{$repo_name})) {
			update_github($hash_prj_id{$repo_name}, $repo_id, $repo_name, $github_org);
			log_print("	update [$repo_name] OK!\n");
			$isUpdate=1;
		}
	}
	else {
		import_github($repo_id, $repo_name, $github_org);
		log_print("	import [$repo_name] OK!\n");
	}
}

# Refresh III DevOps tmpl cache
if ($isUpdate>0) {
	log_print("\nRefresh III DevOps tmpl cache..\n");
	#sleep(10); # wait 10 secs for gitlab importing
	refresh_tmpl_cache();
	log_print("OK!\n");
}

exit;