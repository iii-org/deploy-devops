#!/usr/bin/perl
# remote add Kubernetes worker node script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
if (!defined($ARGV[0])) {
	print("Usage: $prgname user\@remote_ip\n");
	exit;
}

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$p_addk8s_sh = "$nfs_dir/deploy-config/add_k8s.sh";
if (!-e $p_addk8s_sh) {
	log_print("The addk8s_sh file [$p_config] does not exist!\n");
	exit;
}

$rancher_chk = "https://$rancher_ip:3443";
$addk8s_cmd = `cat $p_addk8s_sh`;
if (index($addk8s_cmd, $rancher_chk)<0) {
	log_print("The addk8s_sh file [$p_config] may be wrong! [$rancher_chk] is not exist!\n");
	exit;
}

#$harbor_cert = "$data_dir/harbor/certs/$harbor_ip.crt";
#if (!-e $harbor_cert) {
#	log_print("The Harbor server cert file [$harbor_cert] does not exist!\n");
#	exit;
#}


# copy iiidevops_install.pl, add_k8s_node_sh, habor_server_cert to remote k8s node
#$cmd = "scp $Bin/iiidevops_install.pl $p_addk8s_sh $harbor_cert $ARGV[0]:~";
$cmd = "scp $Bin/iiidevops_install.pl $p_addk8s_sh $ARGV[0]:~";
log_print("-----\nCopy files to $ARGV[0]..\n");
$cmd_msg = `$cmd`;
log_print("\n");

# run and get remote k8s node info
#$cmd = "ssh $ARGV[0] \"chmod a+x ~/add_k8s.sh; sudo -S perl ~/iiidevops_install.pl local; sudo -S ~/add_k8s.sh; showmount -e $nfs_ip; sudo -S cp ~/$harbor_ip.crt /usr/local/share/ca-certificates/; sudo update-ca-certificates; sudo systemctl restart docker.service; ls /etc/ssl/certs | awk /$harbor_ip/\"";
$cmd = "ssh $ARGV[0] \"chmod a+x ~/add_k8s.sh; sudo -S perl ~/iiidevops_install.pl local; sudo -S ~/add_k8s.sh; showmount -e $nfs_ip\"";
log_print("-----\nInstall and get remote k8s node info..\n");
$cmd_msg = `$cmd`;
#system($cmd);
log_print("-----\n$cmd_msg\n\n");

# Check remote k8s node info
$docker_check = (index($cmd_msg, "Install docker 19.03.14 ..OK!")<0)?"ERROR!":"OK!";
$kubectl_check = (index($cmd_msg, "Install kubectl v1.18 ..OK!")<0)?"ERROR!":"OK!";
$helm_check = (index($cmd_msg, "Install helm v3.5 ..OK!")<0)?"ERROR!":"OK!";
$nfs_check = (index($cmd_msg, "$nfs_dir *")<0)?"ERROR!":"OK!";
$harbor_cert_check = (index($cmd_msg, "$harbor_ip.pem")<0)?"ERROR!":"OK!";
log_print("-----Validation results-----\n");
log_print("Docker    	: $docker_check\n");
log_print("Kubectl   	: $kubectl_check\n");
log_print("Helm	     	: $helm_check\n");
log_print("NFS Client 	: $nfs_check\n");
#log_print("Harbor Cert	: $harbor_cert_check\n");

$p_kube_config = "$nfs_dir/kube-config/config";
if (!-e $p_kube_config) {
	log_print("Please goto Rancher Web - $rancher_chk to get the status of added node of k8s cluster!\n");
	exit;
}

#kubectl get node
#NAME          STATUS   ROLES                      AGE   VERSION
#pve-devops2   Ready    controlplane,etcd,worker   53m   v1.18.12
#Error from server (ServiceUnavailable): the server is currently unable to handle the request (get nodes)
$cmd = "kubectl get node";
$isChk=1;
$count=0;
while ($isChk && $count<10) {
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg");
	$isChk = (index($cmd_msg, 'Error')>=0 || index($cmd_msg, 'Ready')<0)?1:0;
	$count ++;
	sleep($isChk);
}
if ($isChk) {
	log_print("\nFailed to join Kubernetes!\n");
	exit;
}
log_print("\nSuccessfully joined Kubernetes!\n");
exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}