#!/usr/bin/perl
# Install Harbor service script
#
use FindBin qw($Bin);
use MIME::Base64;
use POSIX qw(strftime);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n\n");
	exit;
}
require($p_config);

if ($harbor_ip eq '') {
	print("The harbor_ip in [$p_config] is ''!\n\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (lc($ARGV[0]) eq 'create_dockerhub_proxy') {
	create_dockerhub_proxy();
	exit;
}

if (lc($ARGV[0]) eq 'offline'){
	create_dockerhub();
	exit;
}

if (lc($ARGV[0]) eq 'manual_secret_tls') {
	manual_secret_tls();
}
else {
	# Check Harbor service is working
	if (get_service_status('harbor')) {
		log_print("Harbor is running, I skip the installation!\n\n");
		exit;
	}
	log_print("Install Harbor ..\n");
	install_harbor();
}

# Check Harbor service is working
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (!get_service_status('harbor'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy Harbor!\n");
	exit;
}
$the_url = get_domain_name('harbor');
log_print("Successfully deployed Harbor! URL - https://$the_url\n");

# create dockerhub proxy project
if ($deploy_env eq 'offline') {
	create_dockerhub();
} else {
	create_dockerhub_proxy();
}
exit;

sub install_harbor {
# Deploy Harbor on kubernetes cluster

	# Add helm chart harbor repo - https://artifacthub.io/packages/helm/harbor/harbor/1.5.5
	$cmd = "helm repo add harbor https://helm.goharbor.io";
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg-----\n");	

	# Modify harbor/nfs-client-provisioner-pv.yaml.tmpl
	$yaml_path = "$Bin/../harbor/";
	$yaml_file = $yaml_path.'nfs-client-provisioner-pv.yaml';
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{nfs_ip}}/$nfs_ip/g;
	$template =~ s/{{nfs_dir}}/$nfs_dir/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
	
	log_print("Deploy K8s Volumes..\n");
$cmd =<<END;
kubectl apply -f $yaml_path/nfs-client-provisioner-serviceaccount.yaml;
kubectl apply -f $yaml_path/nfs-client-provisioner-runner-clusterrole.yaml;
kubectl apply -f $yaml_path/run-nfs-client-provisioner-clusterrolebinding.yaml;
kubectl apply -f $yaml_path/leader-locking-nfs-client-provisioner-role.yaml;
kubectl apply -f $yaml_path/leader-locking-nfs-client-provisioner-rolebinding.yaml;
kubectl apply -f $yaml_path/iiidevops-nfs-storage-storageclass.yaml;
kubectl apply -f $yaml_file

END
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg-----\n");

	# Modify harbor/harbor-lite-install.yaml.tmpl
	$harbor_domain_name = get_domain_name('harbor');
	$harbor_ip_domain_name = ($deploy_mode eq 'IP')?$harbor_ip:$harbor_domain_name;
	
	$IP_type =<<END;
  type: nodePort
  tls:
    enabled: true
    certSource: auto
    auto:
      commonName: harbor-common-tls
    secret:
      secretName: "harbor-tls"
  nodePort:
    name: devops-harbor
    ports:
      https:
        port: 443
        nodePort: 32443
  ingress:
    hosts:
      core: $harbor_ip_domain_name
    controller: default
externalURL: https://$harbor_domain_name
END
	$DNS_type =<<END;
  type: ingress
  tls:
    enabled: true
    certSource: auto
    secret:
      secretName: "harbor-self-tls"	
  ingress:
    hosts:
      core: $harbor_domain_name
    controller: default
externalURL: https://$harbor_domain_name
END
	$expose_type = ($deploy_mode eq 'IP')?$IP_type:$DNS_type;
	$yaml_path = "$Bin/../harbor/";
	$yaml_file = $yaml_path.'harbor-lite-install.yaml';
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
	$template =~ s/{{harbor_db_password}}/$harbor_db_password/g;
	$template =~ s/{{expose_type}}/$expose_type/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);

	log_print("Deploy Harbor service..\n");
	$cmd = "helm install harbor -f $yaml_file $Bin/harbor-1.5.5.tgz" ;
	##$cmd = "helm install harbor --version 1.5.5 harbor/harbor -f $yaml_file";
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg-----\n");
	if ($deploy_mode eq 'DNS') {
		$cmd_service = `kubectl apply -f $yaml_path/harbor-nginx/`;
	}
	
	# export harbor helm install values yaml
	$datestring = strftime "%Y%m%d%H%M", localtime;
	$cmd_msg = `helm get values harbor > $nfs_dir/deploy-config/harbor-install-$datestring.yaml`;
	log_print("output harbor yaml : $nfs_dir/deploy-config/harbor-install-$datestring.yaml\n");

	# Display Wait 3 min. message
	log_print("It takes 1 to 3 minutes to deploy Harbor service. Please wait.. \n");

	return;
}
sub create_dockerhub {
# Add dockerhub Registry & create dockerhub Proxy Cache Project
	$harbor_key = encode_base64("admin:$harbor_admin_password");
	$harbor_key =~ s/\n|\r//;
	$harbor_domain_name = get_domain_name('harbor');

$cmd =<<END;
curl -s -k --location --request POST 'https://$harbor_domain_name/api/v2.0/projects' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
  "project_name": "dockerhub",
  "storage_limit": -1,
  "public": true
}'
END
	$isRun=1;
	$count=0;
	while ($isRun && $count<10) {
		$isRun=0;
		$cmd_msg = `$cmd`;
		if ($cmd_msg ne '' && index($cmd_msg, "The project named dockerhub already exists")<=0) {
			log_print('.');
			#log_print("Create dockerhub Proxy Cache Project Error: $cmd_msg");
			sleep(5);
			$count ++;
			$isRun=1;
		}
	}
	if (index($cmd_msg, "The project named dockerhub already exists")>0) {
		log_print("The dockerhub Projcet is already exists, skip adding.\n");
	}
	else {
		log_print("\nAdd dockerhub Projcet OK.\n");
	}
	
	return;
}

sub create_dockerhub_proxy {
# Add dockerhub Registry & create dockerhub Proxy Cache Project
	$harbor_key = encode_base64("admin:$harbor_admin_password");
	$harbor_key =~ s/\n|\r//;
	$harbor_domain_name = get_domain_name('harbor');
$cmd =<<END;
curl -s -k --location --request POST 'https://$harbor_domain_name/api/v2.0/registries' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
  "name": "dockerhub",
  "url": "https://hub.docker.com",
  "insecure": false,
  "type": "docker-hub",
  "description": "Default Harbor Projcet Proxy Cache"
}'
END
	$isRun=1;
	$count=0;
	while ($isRun && $count<10) {
		$isRun=0;
		$cmd_msg = `$cmd`;
		if ($cmd_msg ne '' && index($cmd_msg, "'dockerhub' is already used")<=0) {
			log_print('.');
			#log_print("Add dockerhub Registry Error: $cmd_msg");
			sleep(5);
			$count ++;
			$isRun=1;
		}
	}
	if (index($cmd_msg, "'dockerhub' is already used")>0) {
		log_print("The dockerhub Registry is already exists, skip adding.\n");
	}
	else {
		log_print("\nAdd dockerhub Registry OK.\n");
	}
	
$cmd =<<END;
curl -s -k --location --request POST 'https://$harbor_domain_name/api/v2.0/projects' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
  "project_name": "dockerhub",
  "registry_id": 1,
  "storage_limit": -1,
  "metadata": {
    "enable_content_trust": "false",
	"auto_scan": "true",
	"reuse_sys_cve_whitelist": "true",
	"public": "true"
  },
  "public": true
}'
END
	$isRun=1;
	$count=0;
	while ($isRun && $count<10) {
		$isRun=0;
		$cmd_msg = `$cmd`;
		if ($cmd_msg ne '' && index($cmd_msg, "The project named dockerhub already exists")<=0) {
			log_print('.');
			#log_print("Create dockerhub Proxy Cache Project Error: $cmd_msg");
			sleep(5);
			$count ++;
			$isRun=1;
		}
	}
	if (index($cmd_msg, "The project named dockerhub already exists")>0) {
		log_print("The dockerhub Projcet is already exists, skip adding.\n");
	}
	else {
		log_print("\nAdd dockerhub Projcet OK.\n");
	}
	
	return;
}

sub manual_secret_tls {
	if ($harbor_domain_name_tls eq '') {
		log_print("The Secert TLS is not defined!\n");
		exit;
	}
	if ($harbor_domain_name eq '') {
		log_print("The Harbor domain name is not defined!\n");
		exit;
	}
	
	# Get harbor database info.
	$harbor_db_key = `kubectl get secrets/harbor-harbor-database --template={{.data.POSTGRES_PASSWORD}} | base64 -d`;
	if ($harbor_db_key ne $harbor_admin_password && $harbor_db_key ne $harbor_db_password) {
		log_print("Get Harbor database info. failed!\n");
		exit;
	}
	
	# Check & import cert files
	$cert_path = "$nfs_dir/deploy-config/";
	$cert_path = (-e $cert_path.'harbor-cert/')?$cert_path.'harbor-cert/':$cert_path.'devops-cert/';
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
	system("$Bin/../bin/import-secret-tls.pl $harbor_domain_name_tls $cer_file $key_file");
	if (!check_secert_tls($harbor_domain_name_tls)) {
		log_print("The Secert TLS [$harbor_domain_name_tls] does not exist in K8s!\n");
		exit;		
	}

	# Add helm chart harbor repo - https://artifacthub.io/packages/helm/harbor/harbor/1.5.5
	$cmd = "helm repo add harbor https://helm.goharbor.io";
	$cmd_msg = `$cmd 2>&1`;
	log_print("-----\n$cmd_msg-----\n");	
	
	$yaml_path = "$Bin/../harbor/";
	$yaml_file = $yaml_path.'harbor-manual-secret.yaml';
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
	$template =~ s/{{harbor_db_password}}/$harbor_db_key/g;
	$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
	$template =~ s/{{harbor_domain_name_tls}}/$harbor_domain_name_tls/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
	
	log_print("Upgrade Harbor service..\n");
	$cmd = "helm upgrade harbor --version=1.5.5 harbor/harbor -f $yaml_file --timeout=3600s --wait";
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg-----\n");
	
	# export harbor helm install values yaml
	$datestring = strftime "%Y%m%d%H%M", localtime;
	$cmd_msg = `helm get values harbor > $nfs_dir/deploy-config/harbor-install-$datestring.yaml`;
	log_print("output harbor yaml : $nfs_dir/deploy-config/harbor-install-$datestring.yaml\n");

	# Display Wait 3 min. message
	log_print("It takes 1 to 3 minutes to upgrade Harbor service. Please wait.. \n");

	return;
}
