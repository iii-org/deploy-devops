#!/usr/bin/perl
# Fix Pipeline after rehook (Rancher & Gitlab)
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
require("$Bin/../lib/iiidevops_lib.pl");

if ($gitlab_domain_name_tls eq '' || $gitlab_domain_name eq '') {
	print("The GitLab TLS [$gitlab_domain_name_tls] or GitLab domain [$gitlab_domain_name] is not set!\n");
	exit;
}

$iiidevops_ver = get_iiidevops_ver();
if ($iiidevops_ver eq '') {
	print("The III DevOps version is too old, Please upgrade first!\n");
	exit;
}

if (lc($ARGV[0]) ne 'force') {
	print("\nWARNING!!!\n You can only run the script after re-hooking the Rancher pipeline using GitLab. And you MUST input the argument 'Force' to execute the script. After the script is executed, the pipeline history data of all projects will be deleted!!!\n\n");
	exit;
}

$api_key = '';
if (!fix_pipeline_api()) {
	print("Fix Pipeline ERR!\n");
	exit;
}
print("Fix Pipeline OK!\n");

if (!fix_gitlab_url()) {
	print("Fix GitLab URL ERR!\n");
	exit;
}
print("Fix GitLab URL OK!\n");

1;