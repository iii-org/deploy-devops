#!/usr/bin/perl
# github project template import script
#
# Usage: sync-prj-templ-offline.pl [github_org (iiidevops-templates)]
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

$is_init = defined($ARGV[0])?lc($ARGV[0]):''; # 'templates-init' : run sync-prj-templ-offline.pl
$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$github_org = (defined($ARGV[1]))?$ARGV[1]:'iiidevops-templates';
$local_group = 'local-templates';

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
$github_group_id = '';
$local_group_id = '';
foreach $group_hash (@ {$hash_msg}) {
	$prg_name = $group_hash->{'name'};
	if ($is_init eq 'templates-init'){
		if ($group_hash->{'name'} ne $github_org) {
			$group_list .= '['.$group_hash->{'name'}.']';
		}
	} 
	else {
		$group_list .= '['.$group_hash->{'name'}.']';
	}
	if ($group_hash->{'name'} eq $github_org) {
        if ($is_init eq 'templates-init') {
            $ret = delete_gitlab_group($group_hash->{'id'});
            if ($ret<0) {
                log_print("Delete GitLab group [$github_org] Error!\n---\n$cmd_msg\n---\n");
                exit;
            }
            log_print("Delete GitLab group [$github_org] OK!\n\n");
        }else {
            $github_group_id = $group_hash->{'id'};
        }
	}
	if ($group_hash->{'name'} eq $local_group) {
                $local_group_id = $group_hash->{'id'};
        }
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
		print("group_id= $ret[id]");
		exit;
	}
	log_print("Add GitLab group [$github_org] OK!\n\n");
    $github_group_id = $ret;

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
	$local_group_id = $ret;
}
else {
	log_print("GitLab group [$local_group] exists!\n\n");
}

chdir "$Bin/github";
print("chdir $Bin/github");
$tmpl_list = `ls *.tar.gz`;

$repo_num=0;
$repo_name_list = '';
foreach $tmpl_name (split(".tar.gz\n", $tmpl_list)) {
	$repo_num++;
	$repo_name_list .= '['.$tmpl_name.']';
	log_print("[$repo_num]:$tmpl_name\n");
}
log_print("GitHub org [$github_org] : $tmpl_name repo(s)\n\n");
if ($repo_num==0){
	exit;
}

##############
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
	if (index($repo_name_list, "[$prj_name]")>=0) {
		delete_gitlab($prj_id);
		log_print("**Remove**:[$prj_id] $prj_name OK!\n");
	}
}

system("echo $v_http://\"root\":\"$gitlab_root_passwd\"\@$gitlab_domain_name > ~/.git-credentials");
system("git config --global credential.$v_http://$gitlab_domain_name.username root");
system("git config --global credential.$v_http://$gitlab_domain_name.password $gitlab_root_passwd");
system("git config --global credential.helper store");

foreach $tmpl_name (split(".tar.gz\n", $tmpl_list)) {
	print("$tmpl_name\n");
	$ret = create_gitlab_group_project($tmpl_name,$github_group_id);
	if ($ret<0) {
		log_print("Add GitLab group [$github_org] project [$tmpl_name] Error!\n---\n$cmd_msg\n---\n");
		exit;
	}
	log_print("Add GitLab group [$github_org] project [$tmpl_name] OK!\n\n");
	$tar_msg = `tar zxvf $Bin/github/$tmpl_name.tar.gz`;
	chdir "$Bin/github/$tmpl_name";
	$git_msg = `git remote rename origin old-origin;git remote add origin $v_http://$gitlab_domain_name/$github_org/$tmpl_name.git;git push -u origin --all;git push -u origin --tags`;
	chdir "$Bin/github";
	$rm_tar_msg = `rm -rf $Bin/github/$tmpl_name*`;
	log_print("\n**ADD**:$tmpl_name OK!\n");
}

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

	return($hash_msg->{'id'});
}
sub delete_gitlab_group {
	my ($p_gitlab_groupid) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X DELETE  https://gitlab-demo.iiidevops.org/api/v4/groups/12
	$cmd = "$v_cmd -s -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X DELETE  $v_http://$gitlab_domain_name/api/v4/groups/$p_gitlab_groupid";
    $cmd_msg = `$cmd`;
    if (index($cmd_msg, "Accepted")>0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'id'};
	}else{
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}
	sleep(5);
	return($p_gitlab_groupid);
}
sub create_gitlab_group_project {
	my ($project_name, $namespace_id) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	# curl -H "Content-Type: application/json" -H "PRIVATE-TOKEN: QMi2xAxxxxxxxxxx-oaQ" -X POST -d '{"name": "iiidevops-templates","path": "iiidevops-templates"}' https://gitlab-demo.iiidevops.org/api/v4/groups/
	#$cmd = "$v_cmd -s --request POST --header \"PRIVATE-TOKEN: $gitlab_private_token\" --data \"name=$project_name&namespace_id=$namespace_id\" $v_http://$gitlab_domain_name/api/v4/projects/";
	$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$project_name\",\"namespace_id\": \"$namespace_id\"}' $v_http://$gitlab_domain_name/api/v4/projects/";
	$cmd_msg = `$cmd`;
	$ret = '';
	if (index($cmd_msg, $project_name)>0){
		$hash_msg = decode_json($cmd_msg);
		$ret = $hash_msg->{'name'};
		print("[$ret]\n");
	}
	if ($ret eq '' || $ret ne $project_name){
		log_print("---\n$cmd_msg\n---\n");
		return(-1);
	}

	return($hash_msg->{'id'});
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
sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";

	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);

    return;
}
