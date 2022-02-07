#!/usr/bin/perl
# Install GitLab service script
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($gitlab_ip eq '') {
	print("The gitlab_ip in [$p_config] is ''!\n\n");
	exit;
}

$p_force=(lc($ARGV[0]) eq 'force');

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (lc($ARGV[0]) eq 'dns_set' || lc($ARGV[0]) eq 'dns_set_force') {
	dns_set();
	exit;
}
if (lc($ARGV[0]) eq 'modify_ingress') {
	modify_ingress();
	exit;
}

# Check GitLab service is working
if (!$p_force && get_service_status('gitlab')) {
	log_print("GitLab is running, I skip the installation!\n\n");
	exit;
}
log_print("Install GitLab ..\n");

# Deploy GitLab on kubernetes cluster
# Modify gitlab/gitlab-deployment.yml.tmpl
$gitlab_ver = '13.12.15';
$gitlab_domain_name = get_domain_name('gitlab');
if ($gitlab_domain_name_tls ne '') {
	# Check & import cert files
	$cert_path = "$nfs_dir/deploy-config/";
	$cert_path = (-e $cert_path.'gitlab-cert/')?$cert_path.'gitlab-cert/':$cert_path.'devops-cert/';
	$cer_file = "$cert_path/fullchain.pem";
	if (!-e $cer_file) {
		log_print("The cert file [$cer_file] does not exist!\n");
		exit;
	}
	$key_file = "$cert_path/privkey.pem";
	if (!-e $key_file) {
		log_print("The key file [$key_file] does not exist!\n");
		exit;
	}
	system("$Bin/../bin/import-secret-tls.pl $gitlab_domain_name_tls $cer_file $key_file");
	if (!check_secert_tls($gitlab_domain_name_tls)) {
		log_print("The Secert TLS [$gitlab_domain_name_tls] does not exist in K8s!\n");
		exit;		
	}

	# Copy to gitlab dir
	$gitlab_ssl_dir = "$nfs_dir/gitlab/config/ssl";
	system("sudo mkdir -p $gitlab_ssl_dir");
	$gitlab_cer_file = "$gitlab_ssl_dir/$gitlab_domain_name.crt";
	system("sudo cp $cer_file $gitlab_cer_file");
	if (!-e $gitlab_cer_file) {
		log_print("Copy cert file to [$gitlab_cer_file] failed!\n");
		exit;
	}
	$gitlab_key_file = "$gitlab_ssl_dir/$gitlab_domain_name.key";
	system("sudo cp $key_file $gitlab_key_file");
	if (!-e $gitlab_key_file) {
		log_print("Copy cert file to [$gitlab_key_file] failed!\n");
		exit;
	}
	
	$gitlab_url = 'https://'.$gitlab_domain_name;
	$external_ur = $gitlab_url;
	$ingress_tmpl_file = 'gitlab-ingress-ssl.yml.tmpl';
}
else {
	$gitlab_url = 'http://'.$gitlab_domain_name;
	$external_ur = 'http://'.$first_ip;
	$ingress_tmpl_file = 'gitlab-ingress.yml.tmpl';
}
$yaml_path = "$Bin/../gitlab/";
$yaml_file = $yaml_path.'gitlab-deployment.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{gitlab_ver}}/$gitlab_ver/g;
$template =~ s/{{gitlab_url}}/$external_ur/g;
$template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
if ($deploy_mode eq 'DNS') {
	$host_aliases =<<END;
hostAliases:
      - hostnames:
        - "$gitlab_domain_name"
        ip: 127.0.0.1
END
	$template =~ s/{{hostAliases}}/$host_aliases/g;
}
else {
	$template =~ s/{{hostAliases}}//g;
}
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

# Modify gitlab/gitlab-ingress.yml.tmpl
$yaml_path = "$Bin/../gitlab/";
$yaml_file = $yaml_path.'gitlab-ingress.yml';
if (uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_path.$ingress_tmpl_file;
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
	$template =~ s/{{gitlab_domain_name_tls}}/$gitlab_domain_name_tls/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
}
else {
	$cmd = "rm -f $yaml_file";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("$cmd Error!\n$cmd_msg-----\n");
	}
}

# Modify gitlab/gitlab-service.yml.tmpl
$yaml_path = "$Bin/../gitlab/";
$yaml_file = $yaml_path.'gitlab-service.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}

$http_type = ($gitlab_domain_name_tls ne '')?'https':'http';
$http_port = ($gitlab_domain_name_tls ne '')?443:80;
$gitlab_port = ($gitlab_domain_name_tls ne '')?32081:32080;
$template = `cat $tmpl_file`;
$template =~ s/{{http_type}}/$http_type/g;
$template =~ s/{{http_port}}/$http_port/g;
$template =~ s/{{gitlab_port}}/$gitlab_port/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);

$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy GitLab..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 2-10 min. message
log_print("It takes 2 to 10 minutes to deploy GitLab service. Please wait.. \n");
sleep(5);

# Check GitLab service is working
$isChk=1;
$count=0;
$wait_sec=1200;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('gitlab'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy GitLab!\n");
	exit;
}

if ($deploy_mode eq 'DNS') {
	dns_set();
}

log_print("Successfully deployed GitLab! URL - $gitlab_url\n");

exit;

# DNS mode set CoreDNS configmap
sub dns_set {
	if ($gitlab_domain_name eq '') {
		log_print("The Gitlab domain name is not defined!\n");
		return;
	}
	if(!$p_force && lc($ARGV[0]) ne 'dns_set_force'){
		$coredns_configmap_cmd = "kubectl get configmap coredns -n kube-system -o jsonpath='{.data.Corefile}'";
		$cmd_msg = `$coredns_configmap_cmd`;
		if(index($cmd_msg,$gitlab_domain_name)>=0) {
			log_print("The DNS is already set up !\n");
			return;
		}
	}

	$gitlab_cluster_ip = `kubectl get svc gitlab-service -o jsonpath='{.spec.clusterIP}'`;
	$yaml_path = "$Bin/../gitlab/";
	$yaml_file = $yaml_path.'coredns-configmap.yml';
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		return;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{gitlab_cluster_ip}}/$gitlab_cluster_ip/g;
	$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
	$cmd = "kubectl apply -f $yaml_file ; kubectl rollout restart deployment rancher -n cattle-system";
	$cmd_msg = `$cmd`;
	log_print("Set GitLab Domain on K8s CoreDNS...\n");
	# check deploy status
	$isChk=1;
	while($isChk) {
		sleep($isChk);
		$isChk = 0;
		foreach $line (split(/\n/, `kubectl get deployment -n cattle-system | grep rancher`)) {
			$line =~ s/( )+/ /g;
			($l_name, $l_ready, $l_update, $l_available, $l_age) = split(/ /, $line);
			($l_ready_pod, $l_replica_pod) = split("/", $l_ready);
			if ($l_replica_pod ne $l_update || $l_replica_pod ne $l_available) {
				log_print("...");
				$isChk = 3;
			} 
		}
	}
	log_print("Update setting OK\n");

	return;
}

sub modify_ingress {
	if ($gitlab_domain_name eq '') {
		log_print("The Gitlab domain name is not defined!\n");
		return;
	}
	$ingress_tmpl_file = ($gitlab_domain_name_tls ne '')?'gitlab-ingress-ssl.yml.tmpl':'gitlab-ingress.yml.tmpl';
	$yaml_path = "$Bin/../gitlab/";
	$yaml_file = $yaml_path.'gitlab-ingress.yml';
	$tmpl_file = $yaml_path.$ingress_tmpl_file;
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		return;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{gitlab_domain_name}}/$gitlab_domain_name/g;
	$template =~ s/{{gitlab_domain_name_tls}}/$gitlab_domain_name_tls/g;
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
	$cmd = "kubectl apply -f $yaml_file";
	$cmd_msg = `$cmd`;
	log_print("$cmd_msg");
	return;
}