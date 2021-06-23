#!/usr/bin/perl
# Install iiidevops base applications script
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
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (lc($ARGV[0]) eq 'manual_secret_tls') {
	manual_secret_tls();
}
else {
	install_k8s();
}

# Verify kubeconf & Check kubernetes status.
log_print("Verify kubeconf & Check kubernetes status..\n");
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('kubernetes'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy K8s!\n");
	exit;
}
log_print("Successfully deployed K8s!\n");
 
# Create Namespace on kubernetes cluster
$cmd = "kubectl apply -f $Bin/../kubernetes/namespaces/account.yaml";
log_print("Create Namespace on kubernetes cluster..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n\n");
if (index($cmd_msg, 'namespace/account created')<0 && index($cmd_msg, 'namespace/account unchanged')<0) {
	log_print("Failed to create namespace on kubernetes cluster!\n");
	exit;
}
log_print("Create namespace on kubernetes cluster OK!\n");

exit;

sub install_k8s {
	# Check K8s service is working
	if (get_service_status('kubernetes')) {
		log_print("K8s is running, I skip the installation!\n\n");
		exit;
	}
	if ($ingress_domain_name_tls ne '' ) {
		if (!check_secert_tls($ingress_domain_name_tls)) {
			log_print("The Secert TLS [$ingress_domain_name_tls] does not exist in K8s!\n");
			exit;
		}
	}
	log_print("Install K8s ..\n");

	# Gen K8s ssh key
	if (!-e "$nfs_dir/deploy-config/id_rsa") {
		$cmd = "sudo -u rkeuser ssh-keygen -t rsa -C '$admin_init_email' -f $nfs_dir/deploy-config/id_rsa -q -N '';mkdir -p ~rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* ~rkeuser/.ssh/;chown -R rkeuser:rkeuser ~rkeuser/.ssh/";
		system($cmd);
	}
	$cmd = "mkdir -p /home/rkeuser/.ssh/;chown -R rkeuser:rkeuser /home/rkeuser/.ssh/;cp -a $nfs_dir/deploy-config/id_rsa* /home/rkeuser/.ssh/;";
	$cmd .= "cp $nfs_dir/deploy-config/id_rsa.pub /home/rkeuser/.ssh/authorized_keys;chmod 600 /home/rkeuser/.ssh/authorized_keys;";
	system($cmd);

	# Trust first node & Check rkeuser permission
	$cmd = "ssh -o StrictHostKeychecking=no $first_ip \"docker ps\"";
	$cmd_msg = `$cmd 2>&1`;
	$chk_key = 'CREATED';
	#CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS               NAMES
	if (index($cmd_msg, $chk_key)<0) {
		log_print("Verify rkeuser permission for running docker failed!\n");
		exit;
	}
	log_print("Verify rkeuser permission for running docker OK!\n");

	# Install K8s
	system("$Bin/update-k8s-setting.pl Initial $first_ip");
	system("sudo -u rkeuser rke up --config $nfs_dir/deploy-config/cluster.yml");

	$cmd = "cp -a $nfs_dir/deploy-config/kube_config_cluster.yml $nfs_dir/kube-config/config;ln -f -s $nfs_dir/kube-config/config ~rkeuser/.kube/config";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("Copy kubeconf failed!..\n$cmd_msg\n");
		exit;
	}

	return;
}

sub manual_secret_tls {
	if ($ingress_domain_name_tls eq '') {
		log_print("The Secert TLS is not defined!\n");
		exit;
	}
	if ($ingress_domain_name eq '') {
		log_print("The ingress domain name is not defined!\n");
		exit;
	}
	if (!check_secert_tls($ingress_domain_name_tls)) {
		log_print("The Secert TLS [$ingress_domain_name_tls] does not exist in K8s!\n");
		exit;		
	}

	# Update K8s cluster	
	system("$Bin/update-k8s-setting.pl TLS localhost");
	system("sudo -u rkeuser rke up --config $nfs_dir/deploy-config/cluster.yml");
	

	return;
}