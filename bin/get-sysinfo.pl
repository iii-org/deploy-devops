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

# iiidevops
$deploy_ver = get_nexus_info('deploy_version');
$deploy_uuid = get_nexus_info('deployment_uuid');
$iiidevops_ver = get_iiidevops_ver('raw');

# k8s
$k8s_node_json = `kubectl get node -o json`;
$k8s_pod_json = `kubectl get pod -o json`;
$k8s_namespace_json = `kubectl get namespace -o json`;

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

$json_ver = 20210806001;
$json_data = <<END;
{
	"json_ver" : $json_ver,
	"iiidevops" : {
		"deploy_version" : "$deploy_ver",
		"deployment_uuid" : "$deploy_uuid",
		"api_version" : $iiidevops_ver
	},
	"k8s" : {
		"node" : 
$k8s_node_json ,
		"pod" : 
$k8s_pod_json ,
		"namespace" : 
$k8s_namespace_json
	},
	"os" : {
		"hostname" : "$hostname",
		"issue" : "$os_issue",
		"meminfo" : {
$meminfo_json
		}
	}
}
END

print($json_data);
