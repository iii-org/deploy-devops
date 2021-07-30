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

$is_update = defined($ARGV[0])?lc($ARGV[0]):''; # 'gitlab_update' : run catalog url to gitlab
$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$secrets_path = "$Bin/../devops-api/secrets/";
$api_key = '';

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
$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/groups/";
log_print("Get GitLab group list..\n");
$cmd_msg = `$cmd`;
$hash_msg = decode_json($cmd_msg);
$group_list = '';
$helm_catalog_group_id = '';
foreach $group_hash (@ {$hash_msg}) {
	if ($is_init eq 'gitlab_update'){
		if ($group_hash->{'name'} ne $github_org) {
			$group_list .= '['.$group_hash->{'name'}.']';
		}
	} 
	else {
		$group_list .= '['.$group_hash->{'name'}.']';
	}
	if ($group_hash->{'name'} eq $helm_catalog_group) {
		if ($is_update eq 'gitlab_update') {
			$ret = $helm_catalog_group_id = $group_hash->{'id'};
			if ($ret<0) {
                log_print("Delete GitLab group [$helm_catalog_group] Error!\n---\n$cmd_msg\n---\n");
                exit;
            }
			log_print("Delete GitLab group [$helm_catalog_group] OK!\n\n");
		}else {
			$group_list .= '['.$group_hash->{'name'}.']';
		}
	}
}
if ($group_list eq '') {
	log_print("---\n$cmd\n---\n$cmd_msg\n---\n");
}
else {
	log_print("group_list : $group_list\n");
}

# Create $helm_catalog_group group
if (index($group_list, "[$helm_catalog_group]")<0) {
	$ret = create_gitlab_group($helm_catalog_group);
	if ($ret<0) {
		log_print("Add GitLab group [$helm_catalog_group] Error!\n---\n$cmd_msg\n---\n");
		print("group_id= $ret[id]");
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
$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/groups/$helm_catalog_group/projects?per_page=100";
log_print("Get GitLab group $helm_catalog_group project list..\n");
$cmd_msg = `$cmd`;
if (index($cmd_msg, '"message"')>0) {
	log_print("Get GitLab group [$helm_catalog_group] projects Error!\n---\n$cmd_msg\n---\n");
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
	log_print("---\n$cmd\n---\n$cmd_msg\n---\n");
}
else {
	log_print("prj_name_list : $prj_name_list\n");
}

if (index($prj_name_list, "[$helm_catalog]")<0) {
	$ret = create_gitlab_group_project($helm_catalog,$helm_catalog_group_id);
	$helm_catalog_url = $project_hash->{'web_url'};
	if ($ret<0) {
		log_print("Add GitLab group [$helm_catalog_group] project [$helm_catalog] Error!\n---\n$cmd_msg\n---\n");
		exit;
	}
	log_print("Add GitLab group [$helm_catalog_group] project [$helm_catalog] OK!\n\n");
	if (index($ret, $helm_catalog)>0){
		$hash_msg = decode_json($ret);
		$prj_name = $hash_msg->{'name'};
		$helm_catalog_url = $hash_msg->{'web_url'};
		$git_url = $hash_msg->{'http_url_to_repo'};
		print("\nhelm_catalog_group_id: $helm_catalog_group_id \nhash_msg: $hash_msg \nprj_name: $prj_name \nhelm_catalog_url:$helm_catalog_url \ngit_url:$git_url\n");
		print("Create $prj_name Success\n");
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
		print("Add Gitlab Helm Catalog [$helm_catalog] templates\n");
	}
}
else {
	log_print("GitLab project [$helm_catalog_group] exists!\n\n");
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
	print("$name : $ret_msg\n");
}
else {
	if($is_update eq 'gitlab_update') {
		$ret_msg = update_catalogs_api($name, %key_value);
		print("Update catalog [$name : $ret_msg]\n");
		refresh_catalogs_api();
	}
	else {
		print("$name : already exists, Skip!\n");
	}
}

exit;

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

sub update_catalogs_api {
	my ($p_name, %key_value) = @_;

	if ($api_key eq '') {
		get_api_key_api();
	}
	
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
	
	$cmd = <<END;
curl -s --location --request PUT '$iiidevops_api/rancher/catalogs/$p_name' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json' --data-raw '$template'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_msg = 'OK!';
	}
	else {
		print("update catalogs Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);	
}

sub delete_catalogs_api {
	my ($p_name) = @_;

	if ($api_key eq '') {
		get_api_key_api();
	}
	
	$cmd = <<END;
curl -s --location --request DELETE '$iiidevops_api/rancher/catalogs/$p_name' --header 'Authorization: Bearer $api_key'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	print($message);
	if ($message eq 'success') {
		$api_msg = 'OK!';
	}
	else {
		print("delete catalogs Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);	
}

sub refresh_catalogs_api {
	if ($api_key eq '') {
		get_api_key_api();
	}
	
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/rancher/catalogs_refresh' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_msg = 'refresh catalogs OK!';
	}
	else {
		print("refresh catalogs Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);	
}

sub create_gitlab_group {
	my ($p_gitlab_groupname) = @_;
	my ($cmd, $cmd_msg, $ret, %hash_msg);
	
	$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$p_gitlab_groupname\",\"path\": \"$p_gitlab_groupname\",\"visibility\":\"public\"}' $v_http://$gitlab_domain_name/api/v4/groups/";
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
	
	$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"$project_name\",\"namespace_id\": \"$namespace_id\",\"visibility\":\"public\"}' $v_http://$gitlab_domain_name/api/v4/projects/";
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

	return($cmd_msg);
}

sub delete_gitlab {
	my ($p_gitlab_id) = @_;
	my ($cmd, $cmd_msg);

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

1;