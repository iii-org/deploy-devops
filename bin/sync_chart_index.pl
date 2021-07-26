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
$helm_catalog = 'devops-charts-pack-and-index';
$helm_catalog_url = '';
foreach $item (@{ $hash_catalogs->{'data'} }) {
        $catalogs_name_list .= "[$item->{'name'}]";
}

if ($iiidevops_ver ne 'develop') {

	my $p_tar = "$Bin/$helm_catalog.tar.gz";
	if (!-e $p_tar) {
		print("The file [$p_tar] does not exist!\n");
		exit; 
	}

	$gitlab_domain_name = get_domain_name('gitlab');
	$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
	$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';

	$cmd = "$v_cmd -s --header \"PRIVATE-TOKEN: $gitlab_private_token\" $v_http://$gitlab_domain_name/api/v4/projects";
	print("Get GitLab project list..\n");
	$cmd_msg = `$cmd`;
	if (index($cmd_msg, '"message"')>0) {
		log_print("Get GitLab projects Error!\n---\n$cmd_msg\n---\n");
		exit;
	}

	$hash_gitlab_project = decode_json($cmd_msg);
	$prj_name_list = '';
	foreach $project_hash (@ {$hash_gitlab_project}) {
		if ($project_hash->{'name'} eq $helm_catalog) {
			if($is_update eq 'gitlab_update') {
				$prj_id = $project_hash->{'id'};
				$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X DELETE $v_http://$gitlab_domain_name/api/v4/projects/$prj_id";
				$cmd_msg = `$cmd`;
				if (index($cmd_msg, "Accepted")>0){
					print("Delete Project_id: $prj_id Success\n");
					sleep(5);
				}
			}else{
				$helm_catalog_url = $project_hash->{'web_url'};
			}
		}
		if($is_update ne 'gitlab_update') {
			$prj_name_list .= '['.$project_hash->{'name'}.']';
		}
	}

	if (index($prj_name_list, '['.$helm_catalog.']')<0) {
		#Create Gitlab Helm Catalog Project 

		$cmd = "$v_cmd -s -H \"Content-Type: application/json\" -H \"PRIVATE-TOKEN: $gitlab_private_token\" -X POST -d '{\"name\": \"devops-charts-pack-and-index\",\"visibility\":\"public\"}' $v_http://$gitlab_domain_name/api/v4/projects";
		$cmd_msg = `$cmd`;
		$ret = '';
		if (index($cmd_msg, $helm_catalog)>0){
			$hash_msg = decode_json($cmd_msg);
			$ret = $hash_msg->{'name'};
			$helm_catalog_url = $hash_msg->{'web_url'};
			$git_url = $hash_msg->{'http_url_to_repo'};
			print("Create $ret Success\n");
			# push Helm Catalog Project to GitLab
			system("git config --global user.name \"Administrator\"");
			system("git config --global user.password \"$gitlab_root_passwd\"");
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
}

# iii-dev-charts3
$name = 'iii-dev-charts3';
if ($iiidevops_ver eq 'develop') {
	$key_value{'url'} = 'https://raw.githubusercontent.com/iii-org/devops-charts-pack-and-index/develop/';
}
else {
	$key_value{'url'} = $helm_catalog_url;
}

if (index($catalogs_name_list, '['.$name.']')<0) {
	$ret_msg = add_catalogs($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	if($is_update eq 'gitlab_update') {
		$ret_msg = refresh_catalogs_api();
		print("$name : $ret_msg\n");
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

#curl --location --request POST 'http://10.20.0.68:31850/user/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "username": "super",
# "password": "IIIdevops123!"
#}'
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

1;