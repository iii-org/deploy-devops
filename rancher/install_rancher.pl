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
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check Rancher service is working
if (get_service_status('rancher')) {
	log_print("Rancher is running, I skip the installation!\n\n");
	exit;
}
log_print("Install Rancher ..\n");

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
	$isChk = ($isChk<3)?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}

# Rancher 2.4.15
$rancher_hostname=($deploy_mode eq 'IP')?$rancher_ip:$rancher_domain_name;
##$cmd = <<END;
##helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
##kubectl create namespace cattle-system
##kubectl apply --validate=false -f $Bin/cert-manager.crds.yaml
##kubectl apply -f $Bin/rancher-service.yaml
##helm install rancher rancher-stable/rancher --namespace cattle-system --version 2.4.15 --set hostname=$rancher_hostname
##END
$cmd = <<END;
kubectl create namespace cattle-system
kubectl apply --validate=false -f $Bin/cert-manager.crds.yaml
kubectl apply -f $Bin/rancher-service.yaml
helm install rancher --namespace cattle-system  --set hostname=$rancher_hostname $Bin/rancher

END

log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Modify rancher/rancher-ingress.yaml.tmpl
$yaml_path = "$Bin/../rancher/";
$yaml_file = $yaml_path.'rancher-ingress.yaml';
if (uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{rancher_domain_name}}/$rancher_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
	$cmd = "kubectl apply -f $yaml_file";
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n\n");
}
else {
	$cmd = "rm -f $yaml_file";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("$cmd Error!\n$cmd_msg-----\n");
	}
}

# Display Wait 2-5 min. message
log_print("It takes 2 to 5 minutes to deploy Rancher service. Please wait.. \n");

# Check Rancher service is working
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('rancher'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy Rancher!\n");
	exit;
}
$the_url = get_domain_name('rancher');
log_print("Successfully deployed Rancher! URL - https://$the_url\n");

exit;
