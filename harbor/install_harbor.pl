#!/usr/bin/perl
# Install Harbor service script
#
use FindBin qw($Bin);
use MIME::Base64;
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

# Check Harbor service is working
if (get_service_status('harbor')) {
	log_print("Harbor is running, I skip the installation!\n\n");
	exit;
}
log_print("Install Harbor ..\n");

# Generate install yaml and exec install.sh
install_harbor();

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
create_dockerhub_proxy();

exit;

sub install_harbor {
# Deploy Harbor on kubernetes cluster

	# Add helm chart harbor repo - https://artifacthub.io/packages/helm/harbor/harbor/1.5.2
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
	$yaml_path = "$Bin/../harbor/";
	$yaml_file = $yaml_path.'harbor-lite-install.yaml';
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$harbor_domain_name = get_domain_name('harbor');
	$template = `cat $tmpl_file`;
	$template =~ s/{{harbor_admin_password}}/$harbor_admin_password/g;
	$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);

	log_print("Deploy Harbor service..\n");
	$cmd = "helm install harbor --version 1.5.2 harbor/harbor -f $yaml_file";
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg-----\n");

	# Modify harbor/harbor-ingress.yaml.tmpl
	$yaml_path = "$Bin/../harbor/";
	$yaml_file = $yaml_path.'harbor-ingress.yaml';
	if ($deploy_mode ne '' && uc($deploy_mode) ne 'IP') {
		$tmpl_file = $yaml_file.'.tmpl';
		if (!-e $tmpl_file) {
			log_print("The template file [$tmpl_file] does not exist!\n");
			exit;
		}
		$template = `cat $tmpl_file`;
		$template =~ s/{{harbor_domain_name}}/$harbor_domain_name/g;
		#log_print("-----\n$template\n-----\n\n");
		open(FH, '>', $yaml_file) or die $!;
		print FH $template;
		close(FH);
		$cmd = "kubectl apply -f $yaml_file";
		$cmd_msg = `$cmd`;
		log_print("-----\n$cmd_msg-----\n");
	}
	else {
		$cmd = "rm -f $yaml_file";
		$cmd_msg = `$cmd 2>&1`;
		if ($cmd_msg ne '') {
			log_print("$cmd Error!\n$cmd_msg-----\n");
		}
	}

	# Display Wait 3 min. message
	log_print("It takes 1 to 3 minutes to deploy Harbor service. Please wait.. \n");

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
			log_print("Add dockerhub Registry Error: $cmd_msg");
			sleep(5);
			$count ++;
			$isRun=1;
		}
	}
	if (index($cmd_msg, "'dockerhub' is already used")>0) {
		log_print("The dockerhub Registry is already exists, skip adding.\n");
	}
	else {
		log_print("Add dockerhub Registry OK.\n");
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
			log_print("Create dockerhub Proxy Cache Project Error: $cmd_msg");
			sleep(5);
			$count ++;
			$isRun=1;
		}
	}
	if (index($cmd_msg, "The project named dockerhub already exists")>0) {
		log_print("The dockerhub Projcet is already exists, skip adding.\n");
	}
	else {
		log_print("Add dockerhub Projcet OK.\n");
	}
	
	return;
}
