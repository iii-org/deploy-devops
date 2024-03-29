#!/usr/bin/perl
# Install rancher service script
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
	exit;
}

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

# Rancher 2.4.17
$rancher_hostname=($deploy_mode eq 'IP')?$rancher_ip:$rancher_domain_name;
$cmd = <<END;
kubectl create namespace cattle-system
kubectl apply --validate=false -f $Bin/cert-manager.crds.yaml
kubectl apply -f $Bin/rancher-service.yaml
helm install rancher --namespace cattle-system  --set hostname=$rancher_hostname $Bin/rancher-2.4.17.tgz
END

log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Modify rancher/rancher-ingress.yaml.tmpl
#$yaml_path = "$Bin/../rancher/";
#$yaml_file = $yaml_path.'rancher-ingress.yaml';
#if (uc($deploy_mode) ne 'IP') {
#	$tmpl_file = $yaml_file.'.tmpl';
#	if (!-e $tmpl_file) {
#		log_print("The template file [$tmpl_file] does not exist!\n");
#		exit;
#	}
#	$template = `cat $tmpl_file`;
#	$template =~ s/{{rancher_domain_name}}/$rancher_domain_name/g;
#	#log_print("-----\n$template\n-----\n\n");
#	open(FH, '>', $yaml_file) or die $!;
#	print FH $template;
#	close(FH);
#	$cmd = "kubectl apply -f $yaml_file";
#	$cmd_msg = `$cmd`;
#	log_print("-----\n$cmd_msg\n\n");
#}
#else {
#	$cmd = "rm -f $yaml_file";
#	$cmd_msg = `$cmd 2>&1`;
#	if ($cmd_msg ne '') {
#		log_print("$cmd Error!\n$cmd_msg-----\n");
#	}
#}

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

sub manual_secret_tls {
	if ($rancher_domain_name_tls ne 'tls-rancher-ingress') {
		log_print("The Secert TLS must be defined as 'tls-rancher-ingress'!\n");
		exit;
	}
	if ($rancher_domain_name eq '') {
		log_print("The Rancher domain name is not defined!\n");
		exit;
	}
	# Check & import cert files
	$cert_path = "$nfs_dir/deploy-config/";
	$cert_path = (-e $cert_path.'rancher-cert/')?$cert_path.'rancher-cert/':$cert_path.'devops-cert/';
	$cer_file = "$cert_path/fullchain.pem";
	if (!-e $cer_file) {
		log_print("The cert file [$cer_file] does not exist!\n");
		exit;
	}
	if (!check_cert_file($cer_file, $rancher_domain_name)) {
		log_print("The cert file [$cer_file] is invalid!\n");
		exit;
	}
	$key_file = "$cert_path/privkey.pem";
	if (!-e $key_file) {
		log_print("The key file [$key_file] does not exist!\n");
		exit;
	}
	if (!check_key_file($key_file, $cer_file)) {
		log_print("The key file [$key_file] is invalid!\n");
		exit;
	}
	
	# Add helm chart rancher repo - https://releases.rancher.com/server-charts/stable
	$cmd = "helm repo add rancher-stable https://releases.rancher.com/server-charts/stable";
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg-----\n");	

	log_print("Upgrade Rancher service..\n");
	$cmd = "helm upgrade rancher --version=2.4.17 rancher-stable/rancher --namespace cattle-system --set hostname=$rancher_domain_name --set ingress.tls.source=secret --timeout=3600s --wait";
	system($cmd);
	#~/deploy-devops/bin/import-secret-tls.pl tls-rancher-ingress rancher.devops.iiidevops.org/fullchain1.pem rancher.devops.iiidevops.org/privkey1.pem cattle-system
	$cmd = "kubectl -n cattle-system patch deploy/cattle-cluster-agent -p '{\"spec\": {\"template\": {\"spec\": {\"containers\": [{\"name\": \"cluster-register\", \"image\": \"rancher/rancher-agent:v2.4.17\", \"env\": [{\"name\": \"CATTLE_CA_CHECKSUM\", \"value\": \"\"}]}]}}}}'";
	system($cmd);
	$cmd = "kubectl -n cattle-system patch daemonset/cattle-node-agent -p '{\"spec\": {\"template\": {\"spec\": {\"containers\": [{\"name\": \"agent\", \"env\": [{\"name\": \"CATTLE_CA_CHECKSUM\", \"value\": \"\"}]}]}}}}'";
	system($cmd);
	system("$Bin/../bin/import-secret-tls.pl tls-rancher-ingress $cer_file $key_file cattle-system");
	#if (!check_secert_tls('tls-rancher-ingress', 'cattle-system')) {
	#	log_print("The Secert TLS [$rancher_domain_name_tls] does not exist in K8s!\n");
	#	exit;		
	#}	

	# Display Wait 2-5 min. message
	log_print("It takes 2 to 5 minutes to upgrade Rancher service. Please wait.. \n");

	return;
}