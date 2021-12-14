#!/usr/bin/perl
# Add Secrets & Registry for all Rancher Projects
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
require("$Bin/../lib/iiidevops_lib.pl");

$is_offline = defined($ARGV[0])?lc($ARGV[0]):''; # 'offline' : run catalog url to gitlab
$g_secrets_path = "$Bin/secrets/";

#-----
# Add Secrets Credentials
#-----
print("\nAdd Secrets Credentials\n-----\n");
# Get secrets List
$g_hash_secrets = {};
$v_secrets_num = get_secrets_api();
print("now You already have $v_secrets_num secret(s).\n");
$g_secrets_name_list = '';
foreach $v_item (@{ $g_hash_secrets->{'data'} }) {
        $g_secrets_name_list .= "[$v_item->{'name'}]";
}

# nexus
$name = 'nexus';
$key_value{'api-origin'} = $iiidevops_api;
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# checkmarx
$name = 'checkmarx';
$key_value{'client-secret'} = $checkmarx_secret;
$key_value{'cm-url'} = $checkmarx_origin;
$key_value{'username'} = $checkmarx_username;
$key_value{'password'} = $checkmarx_password;
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# webinspect
$name = 'webinspect';
$key_value{'wi-base-url'} = $webinspect_base_url;
$key_value{'wi-type'} = $webinspect_type;
$key_value{'wi-username'} = $webinspect_username;
$key_value{'wi-password'} = $webinspect_password;
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# rancher
$name = 'rancher';
$rancher_hostname=($deploy_mode eq 'IP')?$rancher_ip.':31443':$rancher_domain_name;
$key_value{'rancher-url'} = 'https://'.$rancher_hostname;
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# sonarqube
$name = 'sonarqube';
$key_value{'sonar-url'} = 'http://'.$sonarqube_ip.':31910';
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

# harbor
$name = 'harbor';
$key_value{'harbor-local'} = ($harbor_domain_name eq '')?$harbor_ip.':32443':$harbor_domain_name;
if (index($g_secrets_name_list, '['.$name.']')<0) {
	$ret_msg = add_secrets($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}


#-----
# Add Registry Credentials
#-----
print("\nAdd Registry Credentials\n-----\n");
# Get registry List
$g_hash_registry = {};
$v_registry_num = get_registry_api();
print("now You already have $v_registry_num registry.\n");
$g_registry_name_list = '';
foreach $item (@{ $g_hash_registry->{'data'} }) {
        $g_registry_name_list .= "[$item->{'name'}]";
}

# harbor-local
$name = 'harbor-local';
$url = ($harbor_domain_name eq '')?$harbor_ip.':32443':$harbor_domain_name;
$key_value{'url'} = $url;
$key_value{'username'} = 'admin';
$key_value{'password'} = $harbor_admin_password;
if (index($g_registry_name_list, '['.$name.']')<0) {
	$ret_msg = add_registry($name, %key_value);
	print("$name : $ret_msg\n");
}
else {
	print("$name : already exists, Skip!\n");
}

exit;

sub add_secrets {
	my ($p_name, %key_value) = @_;
	my ($v_json_file, $v_tmpl_file, $v_ret_msg, $v_template, $v_key, $v_api_msg);
	
	$v_json_file = $g_secrets_path.$p_name.'-secret.json';
	$v_tmpl_file = $v_json_file.'.tmpl';
	if (!-e $v_tmpl_file) {
		$v_ret_msg = "The template file [$v_tmpl_file] does not exist!";
		return($v_ret_msg);
	}
	
	$v_template = `cat $v_tmpl_file`;
	foreach $v_key (keys %key_value) {
		$v_template =~ s/{{$v_key}}/$key_value{$v_key}/g;
	}
	#print("-----\n$v_template\n-----\n\n");
	$v_api_msg = add_secrets_api($v_template);
	$v_ret_msg = "Create Secrets $v_json_file..$v_api_msg";
	
	return($v_ret_msg);
}

sub add_registry {
	my ($p_name, %key_value) = @_;
	my ($v_json_file, $v_tmpl_file, $v_ret_msg, $v_template, $v_key, $v_api_msg);

	$v_json_file = $g_secrets_path.$p_name.'-registry.json';
	$v_tmpl_file = $v_json_file.'.tmpl';
	if (!-e $v_tmpl_file) {
		$v_ret_msg = "The template file [$v_tmpl_file] does not exist!";
		return($v_ret_msg);
	}

	$v_template = `cat $v_tmpl_file`;
	foreach $v_key (keys %key_value) {
		$v_template =~ s/{{$v_key}}/$key_value{$v_key}/g;
	}
	#print("-----\n$v_template\n-----\n\n");
	$v_api_msg = add_registry_api($v_template);
	$v_ret_msg = "Create Registry $v_json_file..$v_api_msg";
	
	return($v_ret_msg);
}

1;