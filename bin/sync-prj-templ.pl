#!/usr/bin/perl
# sync project template script
#
# Usage: sync-prj-templ.pl [gitubuser:github_token] [github_org (iiidevops-templates)] 
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

if (!defined($ARGV[0])) {
	print("Usage: $prgname [gitubuser:github_token] [github_org]\n");
	exit;
}

$github_user_token = $ARGV[0];
($cmd_msg, $github_token) = split(':', $github_user_token);
if (length($github_token)!=40) {
	print("github_token:[$github_token] is worng!\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$github_org = (defined($ARGV[1]))?$ARGV[1]:'iiidevops-templates';
$local_group = 'local-templates';

# Get GitHub org $github_org (iiidevops-templates) repo list
# curl -H "Accept: application/vnd.github.inertia-preview+json" https://api.github.com/orgs/iiidevops-templates/repos
$arg_str = ($github_user_token ne '')?"-u $github_user_token ":'';
$cmd = "curl -s $arg_str -H \"Accept: application/vnd.github.inertia-preview+json\" https://api.github.com/orgs/$github_org/repos";
log_print("Get GitHub org $github_org repo list..\n");
$cmd_msg = `$cmd`;
if (index($cmd_msg, 'node_id')<0) {
	log_print("Get GitHub org [$github_org] repos Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
	exit;
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
$gitlab_domain_name = get_domain_name('gitlab');
$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';
# curl --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/groups/
$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/groups/";
log_print("Get GitLab group list..\n");
$cmd_msg = `$cmd`;
$hash_msg = decode_json($cmd_msg);
$group_list = '';
foreach $group_hash (@ {$hash_msg}) {
	$group_list .= '['.$group_hash->{'name'}.']';
}
if ($group_list eq '') {
	log_print("---\n$cmd\n---\n$cmd_msg\n---\n");
}
else {
	log_print("group_list : $group_list\n");
}

# Create $github_org group
if (index($group_list, "[$github_org]")<0) {
	$ret = create_gitlab_group($github_org);
	if ($ret<0) {
		log_print("Add GitLab group [$github_org] Error!\n---\n$cmd_msg\n---\n");
		exit;
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
		exit;
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
$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/groups/$github_org/projects?per_page=100";
log_print("Get GitLab group $github_org project list..\n");
$cmd_msg = `$cmd`;
if (index($cmd_msg, '"message"')>0) {
	log_print("Get GitLab group [$github_org] projects Error!\n---\n$cmd_msg\n---\n");
	exit;
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
foreach $repo_hash (@ {$hash_github_repo}) {
	$idx++;
	$repo_id = $repo_hash->{'id'};
	$repo_name = $repo_hash->{'name'};
	$repo_max_time = ($repo_hash->{'created_at'} gt $repo_hash->{'updated_at'})?$repo_hash->{'created_at'}:$repo_hash->{'updated_at'};
	$repo_max_time = ($repo_max_time gt $repo_hash->{'pushed_at'})?$repo_max_time:$repo_hash->{'pushed_at'};
	log_print("[$idx].	name:".$repo_name." ($repo_max_time)\n");
	if (index($prj_name_list, "[$repo_name]")>=0) {
		log_print("	GitLab-> id:".$hash_prj_id{$repo_name}." path:".$hash_prj_path{$repo_name}." created_at:".$hash_prj_created_at{$repo_name}."\n");
		if ($repo_max_time gt $hash_prj_created_at{$repo_name}) {
			update_github($hash_prj_id{$repo_name}, $repo_id, $repo_name, $github_org);
			log_print("	update [$repo_name] OK!\n");
		}
	}
	else {
		import_github($repo_id, $repo_name, $github_org);
		log_print("	import [$repo_name] OK!\n");
	}
}

exit;

sub create_gitlab_group {
	my ($p_gitlab_groupname) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X POST -d '{"name": "iiidevops-templates","path": "iiidevops-templates"}' https://gitlab-demo.iiidevops.org/api/v4/groups/
	$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$p_gitlab_groupname\",\"path\": \"$p_gitlab_groupname\"}' $v_http://$gitlab_domain_name/api/v4/groups/";	
	$cmd_msg = `$cmd`;
	$ret = '';
	if (index($cmd_msg, $p_gitlab_groupname)>0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'name'};
		print("[$ret]\n");
	}
	if ($ret eq '' || $ret ne $p_gitlab_groupname){
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}

	return(1);
}

sub update_github {
	my ($p_gitlab_id, $p_repo_id, $p_new_name, $p_target_namespace) = @_;
	my ($cmd, $cmd_msg);

	delete_gitlab($p_gitlab_id);
	import_github($p_repo_id, $p_new_name, $p_target_namespace);

	return;
}

sub delete_gitlab {
	my ($p_gitlab_id) = @_;
	my ($cmd, $cmd_msg);

	#curl --request DELETE --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" https://gitlab-demo.iiidevops.org/api/v4/projects/2
	$cmd = "$v_cmd -s --request DELETE --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/projects/$p_gitlab_id";
	$cmd_msg = `$cmd`;
	if (index($cmd_msg, 'Accepted')<0) {
		log_print("delete_gitlab [$p_gitlab_id] Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		exit;
	}
	sleep(5);

	return;
}

sub import_github {
	my ($p_repo_id, $p_new_name, $p_target_namespace) = @_;
	my ($cmd, $cmd_msg, $arg_user);

	# curl --request POST --header "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" --data "personal_access_token=de8b68c3ee3eccdf7d4d69c6260bff66482283a9&repo_id=336984846&new_name=django-postgresql-todo&target_namespace=iiidevops-templates" https://gitlab-demo.iiidevops.org/api/v4/import/github
	$cmd = "$v_cmd -s --request POST --header \"PRIVATE-TOKEN: $gitlab_private_token\" --data \"personal_access_token=$github_token&repo_id=$p_repo_id&new_name=$p_new_name&target_namespace=$p_target_namespace\" $v_http://$gitlab_domain_name/api/v4/import/github";
	$cmd_msg = `$cmd`;
	if (index($cmd_msg, $p_new_name)<0) {
		log_print("import_github [$p_new_name] Error!\n---\n$cmd\n---\n$cmd_msg\n---\n");
		exit;
	}
	
	return;
}

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}