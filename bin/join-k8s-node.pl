#!/usr/bin/perl
# remote join Kubernetes cluster node script
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
if (!defined($ARGV[0]) || !defined($ARGV[1])) {
	print("Usage: $prgname rkeuser\@first_node_ip my_ip [ins_repo]\n");
	exit;
}

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Global Var
$valid_rke_ver = '[v1.2.7][v1.1.19]';

# Check runtime user
$cmd = "whoami";
$cmd_msg = `$cmd 2>&1`;
$chk_key = 'rkeuser';
if (index($cmd_msg, $chk_key)<0) {
	log_print("Must use 'rkeuser' user to join K8s cluster!\n");
	exit;
}

# Check my_ip
$cmd = "ip a";
$cmd_msg = `$cmd 2>&1`;
$chk_key = $ARGV[1].'/';
if (index($cmd_msg, $chk_key)<0) {
	log_print("My IP [$chk_key] is not existed in ip list!\n\n$cmd_msg\n");
	exit;
}

# Gen K8s ssh key
$ssh_key_file = '/home/rkeuser/.ssh/id_rsa';
if (!-e $ssh_key_file) {
	$cmd = "mkdir -p /home/rkeuser/.ssh; ssh-keygen -t rsa -C 'tech\@iii-devops.org' -f $ssh_key_file -q -N ''";
	system($cmd);
}
# Copy ssh key to first_ip
if (!-e $ssh_key_file.'.pub') {
	log_print("Cannot find ssh public key file : [$ssh_key_file.pub]!\n");
	exit;	
}
else {
	$cmd = "ssh-copy-id -f -i $ssh_key_file.pub $ARGV[0]";
	system($cmd);
}

# Get first_node rke version
$cmd = "ssh $ARGV[0] 'rke --version'";
$cmd_msg = `$cmd 2>&1`;
#rke version v1.2.7
if (index($cmd_msg, 'rke')<0) {
	log_print("Get first node rke version Error!\n$cmd_msg");
	exit;
}
$cmd_msg =~ s/\n|\r//g; 
($t1,$t2,$rke_ver) = split(/ /, $cmd_msg);
if (index($valid_rke_ver, "[$rke_ver]")<0) {
	log_print("The first node $cmd_msg is incompatible! Expect : $valid_rke_ver\n");
	exit;
}

# Setting base system version
if ($rke_ver eq 'v1.1.19') {
	# Rancher 2.4.x support version
	$os_ver = '20.04';
	$docker_ver = '19.03.';
	$kubectl_ver = 'v1.18.20';
}
elsif ($rke_ver eq 'v1.2.7') {
	# III DevOps < 1.8 using version
	$os_ver = '20.04';
	$docker_ver = '19.03.';
	$kubectl_ver = 'v1.18.17';
}
else {
	log_print("The first node rke version [$rke_ver] is incompatible!\n");
	exit;
}

if (length(`dpkg -l | grep "ii  iiidevops "`)==0 || !-e '/usr/local/bin/rke') {
	# Download iiidevops_install.pl
	$ins_repo = (!defined($ARGV[2]))?'master':$ARGV[2];
	$cmd = "rm -f ./iiidevops_install.pl.log; wget -O iiidevops_install.pl https://raw.githubusercontent.com/iii-org/deploy-devops/$ins_repo/bin/iiidevops_install.pl; perl ./iiidevops_install.pl $ins_repo $rke_ver";
	system($cmd);
	$cmd_msg = `cat ./iiidevops_install.pl.log`;
	$docker_check = (index($cmd_msg, "Install docker $docker_ver ..OK!")<0)?"ERROR!":"OK!";
	$kubectl_check = (index($cmd_msg, "Install kubectl $kubectl_ver ..OK!")<0)?"ERROR!":"OK!";
	$helm_check = (index($cmd_msg, "Install helm ..OK!")<0)?"ERROR!":"OK!";
	$rke_check = (index($cmd_msg, "Install rke $rke_ver ..OK!")<0)?"ERROR!":"OK!";
}
else {
	$cmd_msg = `docker --version 2>&1`;
	$docker_check = (index($cmd_msg, $docker_ver)<0)?"ERROR!":"OK!";
	$cmd_msg = `kubectl version --client 2>&1`;
	$kubectl_check = (index($cmd_msg, $kubectl_ver)<0)?"ERROR!":"OK!";
	$cmd_msg = `helm version 2>&1`;
	$helm_check = (index($cmd_msg, "Version:")<0)?"ERROR!":"OK!";
	$cmd_msg = `rke --version 2>&1`;
	$rke_check = (index($cmd_msg, $rke_ver)<0)?"ERROR!":"OK!";
}

$chk_key = 'ERROR';
$cmd_msg = $docker_check.$kubectl_check.$helm_check.$rke_check;
if (index($cmd_msg, $chk_key)>=0) {
	log_print("Docker    	: $docker_check\n");
	log_print("Kubectl   	: $kubectl_check\n");
	log_print("Helm	     	: $helm_check\n");
	log_print("RKE	     	: $rke_check\n");
	log_print("--------------------------\n");
	log_print("Validation results failed!\n");
	exit;
}
log_print("Validation results OK!\n");

# Get kube_conf & evn.pl
$kube_conf = '/home/rkeuser/.kube/config';
$cmd = "scp $ARGV[0]:$kube_conf $kube_conf";
$cmd_msg = `$cmd 2>&1`;
if (!-e $kube_conf) {
	log_print("Get kube_conf file [$kube_conf] failed!\n");
	exit;
}

# Check K8s Node
$cmd = 'kubectl get node';
$cmd_msg = `$cmd 2>&1`;
$chk_key = $ARGV[1].' ';
if (index($cmd_msg, $chk_key)>=0) {
	log_print("My IP [$chk_key] is in K8s node list! Stop the process of joining the K8s cluster.\n\n$cmd_msg\n");
	exit;
}

# Get env.pl
$env_file = '/home/rkeuser/deploy-devops/env.pl';
$cmd = "scp $ARGV[0]:$env_file $env_file";
$cmd_msg = `$cmd 2>&1`;
if (!-e $env_file) {
	log_print("Get evn.pl file [$env_file] failed!\n");
	exit;	
}
require($env_file);
require("/home/rkeuser/deploy-devops/lib/common_lib.pl");

# Check nfs_clint, docker permission...
$cmd = "showmount -e $nfs_ip;sudo -u rkeuser docker ps; sudo perl /home/rkeuser/deploy-devops/bin/add-insecure-registries.pl $harbor_ip $harbor_domain_name";
$cmd_msg = `$cmd 2>&1`;
#/iiidevopsNFS *
$nfs_check = (index($cmd_msg, "$nfs_dir *")<0)?"ERROR!":"OK!";
#CONTAINER ID        IMAGE                                             COMMAND                  CREATED             STATUS              
$permission_check = (index($cmd_msg, "CREATED")<0)?"ERROR!":"OK!";
#The Docker of the node should be able to trust 10.20.0.96
$harbor_check = (index($cmd_msg, "The Docker of the node should be able to trust $harbor_ip")<0)?"ERROR!":"OK!";
log_print("NFS Client 	: $nfs_check\n");
log_print("Docker perm 	: $permission_check\n");
log_print("Harbor Trust	: $harbor_check\n");
$chk_key = 'ERROR';
$chk_msg = $nfs_check.$permission_check.$harbor_check;
if (index($chk_msg, $chk_key)>=0) {
	log_print("--------------------------\n");
	log_print("Validation results failed!\n");
	log_print("-----\n$cmd_msg\n\n");
	exit;
}
log_print("Validation results OK!\n");

# Check kubernetes status.
log_print("Check kubernetes status..\n");
if (!get_service_status('kubernetes')) {
	log_print("The Kubernetes cluster is not working properly!\n");
	exit;
}
log_print("Kubernetes cluster is working well!\n");

# trust first node
$cmd ="scp $ARGV[0]:/home/rkeuser/.ssh/id_rsa.pub /home/rkeuser/.ssh/authorized_keys; chmod 600 /home/rkeuser/.ssh/authorized_keys;ssh $ARGV[0] \"ssh -o StrictHostKeychecking=no $ARGV[1] ip a\"";
$cmd_msg = `$cmd 2>&1`;
$chk_key = $ARGV[1];
if (index($cmd_msg, $chk_key)<0) {
	log_print("Set trust first node failed!\n\n$cmd_msg\n");
	exit;
}
log_print("Set trust first node OK!\n");

# Seting my node is ready
$cmd = "ssh $ARGV[0] 'touch $nfs_dir/deploy-config/$ARGV[1].ready; ls -lt $nfs_dir/deploy-config/'";
$cmd_msg = `$cmd 2>&1`;
$chk_key = $ARGV[1].'.ready';
if (index($cmd_msg, $chk_key)<0) {
	log_print("Set $ARGV[1].ready failed!\n");
	log_print("-----\n$cmd_msg\n\n");
	exit;
}
log_print("Wait 10 secs, $ARGV[1] is ready to join K8s cluster!\n");
# Wait 10 secs
sleep(10);

# Exec update-k8s-cluster.pl @first_node
system("ssh $ARGV[0] 'nohup /home/rkeuser/deploy-devops/bin/update-k8s-cluster.pl > /dev/null 2>&1 &'");
log_print("Exec update-k8s-cluster.pl!\n");

# Check K8s Node
$cmd = "kubectl get node | grep '$ARGV[1] '";
$cmd_msg = `$cmd 2>&1`;
$chk_key = ' Ready ';
log_print("--------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("$cmd_msg\n");
log_print("It takes 3 to 10 minutes for $ARGV[1] to join the K8s cluster. Please wait.. \n");
while (index($cmd_msg, $chk_key)<0) {
	if ($cmd_msg eq '') {
		log_print('.');
	}
	else {
		log_print("$cmd_msg");
	}
	sleep(5);
	$cmd_msg = `$cmd 2>&1`;
}
log_print("\n--------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("$cmd_msg\n");
exit;


sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}
