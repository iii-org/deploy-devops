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

$deploy_ver = get_nexus_info('deploy_version');
$deploy_uuid = get_nexus_info('deployment_uuid');
$iiidevops_ver = get_iiidevops_ver('raw');


$json_data = <<END;
{
	"iiidevops" : {
		"deploy_version" : "$deploy_ver",
		"deployment_uuid" : "$deploy_uuid",
		"api_version" : {
$iiidevops_ver
		}
	}
	"os" : {
		"hostname" : "dev-iso",
		"issue" : "Ubuntu 20.04.2 LTS \n \l",
		"meminfo" : {
			"MemTotal" : "16397128 kB",
			"MemFree" : "708996 kB",
			"MemAvailable" : "14005320 kB"
		}
	}
	"k8s" : {
	}
}
END

print($json_data);
