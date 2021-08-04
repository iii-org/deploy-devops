#!/usr/bin/perl
# Get system info
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/common_lib.pl");

$json_ver = 20210804001;
# iiidevops
$deploy_ver = get_nexus_info('deploy_version');
$deploy_uuid = get_nexus_info('deployment_uuid');
$iiidevops_ver = get_iiidevops_ver('raw');
# os
$hostname = `hostname`;
$hostname =~ s/\n|\r//g;
$os_issue = `cat /etc/issue.net`;
$os_issue =~ s/\n|\r//g;
$meminfo = `cat /proc/meminfo | grep Mem`;
$meminfo_json = '';
foreach $line (split(/\n/, $meminfo)) {
	if ($meminfo_json ne '') {
		$meminfo_json .= ",\n";
	}
	($key, $value) = split(/:/, $line);
	$value =~ s/ //g;
	$meminfo_json .= "\t\t\t\"$key\" : \"$value\"";
}

# k8s

$json_data = <<END;
{
	"json_ver" : $json_ver,
	"iiidevops" : {
		"deploy_version" : "$deploy_ver",
		"deployment_uuid" : "$deploy_uuid",
		"api_version" : $iiidevops_ver
	},
	"os" : {
		"hostname" : "$hostname",
		"issue" : "$os_issue",
		"meminfo" : {
$meminfo_json
		}
	},
	"k8s" : {
	}
}
END

print($json_data);
