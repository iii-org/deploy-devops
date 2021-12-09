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
$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}
$kubeconf_str = "--kubeconfig $nfs_dir/kube-config/config";
$k8s_node_json = `$cmd_kubectl $kubeconf_str get node -o json`;
$k8s_pod_json = `$cmd_kubectl $kubeconf_str get pod -o json`;
$k8s_namespace_json = `$cmd_kubectl $kubeconf_str get namespace -o json`;

# os
$hostname = `hostname`;
$hostname =~ s/\n|\r//g;
$os_issue = `cat /etc/issue.net`;
$os_issue =~ s/\n|\r//g;

$cpu_num =  `grep -c -P '^processor\\s+:' /proc/cpuinfo`;
$cpu_model = `grep -m 1 -P '^model name\\s+:' /proc/cpuinfo`;
$cpu_MHz = `grep -m 1 -P '^cpu MHz\\s+:' /proc/cpuinfo`;
$cpu_bogomips = `grep -m 1 -P '^bogomips\\s+:' /proc/cpuinfo`;
$cpu_cache = `grep -m 1 -P '^cache size\\s+:' /proc/cpuinfo`;

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

# packages
$rke_ver = get_system_ver('rke');
$docker_ver = get_system_ver('docker');
$kubectl_ver = get_system_ver('kubectl');

# json
$json_ver = 20211209001;
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
		"cupinfo" : {
			"cores" : $cpu_num,
			"model name" : "$cpu_model",
			"cpu MHz" : $cpu_MHz,
			"bogomips" : $cpu_bogomips,
			"cache size" : "$cpu_cache"
		}
		"meminfo" : {
$meminfo_json
		}
	}
	"packages" : {
		"rke" : "$rke_ver",
		"docker" : "$docker_ver",
		"kubectl" : $kubectl_ver
	}
}
END

print($json_data);
