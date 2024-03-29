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

$cpu_num =  get_cpuinfo('cores');
$cpu_model = get_cpuinfo('model name');
$cpu_MHz = get_cpuinfo('cpu MHz');
$cpu_bogomips = get_cpuinfo('bogomips');
$cpu_cache = get_cpuinfo('cache size');

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
$rancher_ver = get_image_tag('rancher/rancher', 'cattle-system');
$gitlab_ver = call_gitlab_api('GET', 'version');
$redmine_ver = get_image_tag('redmine');
$harbor_ver = get_image_tag('goharbor/harbor-core');
$sonarqube_ver = call_sonarqube_api('GET', 'server/version');

# json
$json_ver = 20220105001;
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
		},
		"meminfo" : {
$meminfo_json
		}
	},
	"packages" : {
		"rke" : "$rke_ver",
		"docker" : "$docker_ver",
		"kubectl" : $kubectl_ver,
		"rancher" : "$rancher_ver",
		"gitlab" : $gitlab_ver,
		"redmine" : "$redmine_ver",
		"harbor" : "$harbor_ver",
		"sonarqube" : "$sonarqube_ver"
	}
}
END

print($json_data);
