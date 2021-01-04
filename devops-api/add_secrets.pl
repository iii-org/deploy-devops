#!/usr/bin/perl
# Add Secrets for all Rancher Projects
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$secrets_path = "$Bin/secrets/";
$api_key = '';

# api-origin
$json_file = $secrets_path.'api-origin.json';
$tmpl_file = $json_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{iiidevops_api}}/$iiidevops_api/g;
#print("-----\n$template\n-----\n\n");
$api_msg = add_secrets($template);
print("Create Secrets $json_file..$api_msg\n");

# checkmarx-secret
$json_file = $secrets_path.'checkmarx-secret.json';
$tmpl_file = $json_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;
$template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
$template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
$template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
#print("-----\n$template\n-----\n\n");
$api_msg = add_secrets($template);
print("Create Secrets $json_file..$api_msg\n");

# gitlab-token
$json_file = $secrets_path.'gitlab-token.json';
$tmpl_file = $json_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{gitlab_private_token}}/$gitlab_private_token/g;
#print("-----\n$template\n-----\n\n");
$api_msg = add_secrets($template);
print("Create Secrets $json_file..$api_msg\n");

# jwt-token
$json_file = $secrets_path.'jwt-token.json';
$tmpl_file = $json_file.'.tmpl';
if (!-e $tmpl_file) {
	print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{jwt_secret_key}}/$jwt_secret_key/g;
#print("-----\n$template\n-----\n\n");
$api_msg = add_secrets($template);
print("Create Secrets $json_file..$api_msg\n");

exit;


#curl --location --request POST 'http://10.20.0.68:31850/user/login' \
#--header 'Content-Type: application/json' \
#--data-raw '{
# "username": "super",
# "password": "IIIdevops123!"
#}'
sub get_api_key {
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
sub add_secrets {
	my ($p_data) = @_;

	if ($api_key eq '') {
		get_api_key();
	}
	
	$cmd = <<END;
curl -s --location --request POST '$iiidevops_api/maintenance/secretes_into_rc_all' --header 'Authorization: Bearer $api_key' --header 'Content-Type: application/json' --data-raw '$p_data'

END
	$api_msg = `$cmd`;
	$hash_msg = decode_json($api_msg);
	$message = $hash_msg->{'message'};
	if ($message eq 'success') {
		$api_key = $hash_ret->{'data'}->{'token'};
		$api_msg = 'OK!';
	}
	else {
		print("add sectets Error:\n$api_msg\n");
		$api_msg = 'Failed!';
	}
	
	return($api_msg);
}