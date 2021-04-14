#!/usr/bin/perl
# Install rancher service script
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
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

log_print("Install Rancher URL: https://$rancher_ip:31443\n");
# Check Rancher is working
$cmd_msg = `nc -z -v $rancher_ip 31443 2>&1`;
$isWorking = index($cmd_msg, 'succeeded!')<0?0:1;
if ($isWorking) {
	log_print("Rancher is running, I skip the installation!\n\n");
	exit;
}

# cert-manager 1.0.4 https://github.com/jetstack/cert-manager/releases/download/v1.0.4/cert-manager.yaml
$cmd = "kubectl apply --validate=false -f $Bin/cert-manager.yaml";
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n");
$cmd = "kubectl get pods --namespace cert-manager";
#NAME                                      READY   STATUS    RESTARTS   AGE
#cert-manager-6cd8cb4b7c-cz4f9             1/1     Running   0          53s
#cert-manager-cainjector-685b87b86-jdv2k   1/1     Running   0          53s
#cert-manager-webhook-76978fbd4c-4qkls     1/1     Running   0          53s
$chk_key = '1/1';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	#log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	log_print($cmd_msg);
	@arr_msg = split("\n", $cmd_msg);
	$isChk = grep{ /$chk_key/} @arr_msg;
	$isChk = ($isChk<3)?1:0;
	$count ++;
	sleep($isChk);
}

# Rancher 2.4.15
$rancher_hostname = ($rancher_domain_name eq '')?$rancher_ip:$rancher_domain_name;
$cmd = <<END;
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
kubectl create namespace cattle-system
kubectl apply --validate=false -f $Bin/cert-manager.crds.yaml
kubectl apply -f $Bin/rancher-service.yaml
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --version 2.4.15 \
  --set hostname=$rancher_hostname
END

log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check Rancher service is working
$cmd = "kubectl -n cattle-system rollout status deploy/rancher";
# deployment "rancher" successfully rolled out
$chk_key = 'successfully!';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	#log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	log_print($cmd_msg);
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("-----\n$cmd_msg-----\n");
if ($isChk) {
	log_print("Failed to deploy Rancher!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Rancher!\n");
exit;


sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}