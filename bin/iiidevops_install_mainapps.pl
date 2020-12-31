#!/usr/bin/perl
# Install iiidevops master node script
#
use FindBin qw($Bin);
use MIME::Base64;
$p_config = "$Bin/../env.pl";
$wait_sec = 600;
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

# Create Data Dir
$cmd = "sudo mkdir -p $data_dir";
$cmd_msg = `$cmd 2 >&1`;
if ($cmd_msg ne '') {
	log_print("Create data directory [$data_dir] failed!\n$cmd_msg\n-----\n");
	exit;
}
log_print("Create data directory OK!\n");

# NFS
$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
log_print("\nInstall & Setting NFS service..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");
# Check NFS service is working
$cmd = "showmount -e $nfs_ip";
$chk_key = $nfs_dir;
$cmd_msg = `$cmd 2>&1`;
log_print("-----\n$cmd_msg-----\n");
if (index($cmd_msg, $chk_key)<0) {
	log_print("NFS configuration failed!\n");
	exit;
}
log_print("NFS configuration OK!\n");

# GitLab
$cmd = "sudo $home/deploy-devops/gitlab/create_gitlab.pl";
log_print("Deploy Gitlab..");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");
# Check GitLab service is working
$cmd = "nc -z -v $gitlab_ip 80";
$chk_key = 'succeeded!';
$cmd_msg = `$cmd 2>&1`;
# Connection to 10.20.0.71 80 port [tcp/*] succeeded!
if (index($cmd_msg, 'succeeded!')<0) {
	log_print("Failed to deploy GitLab!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("OK!\n");
log_print("Successfully deployed GitLab!\n");

# Harbor
$cmd = "sudo $home/deploy-devops/harbor/create_harbor.pl";
print("\nDeploy and Setting Harbor server..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<$wait_sec) {
	print('.');
	$cmd_msg = `curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/registries' 2>&1`;
	#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
	$isChk = index($cmd_msg, 'UNAUTHORIZED')<0?1:0;
	$count ++;
	sleep($isChk);
}
if ($isChk) {
	print("Failed to deploy Harbor!\n");
	print("-----\n$cmd_msg-----\n");
	exit;	
}
else {
	print("OK!\n");
#	print("-----\n$cmd_msg-----\n");
	print("Successfully deployed Harbor!\n");
}

# Add dockerhub Registry & create dockerhub Proxy Cache Project
$harbor_key = encode_base64("admin:$harbor_admin_password");
$harbor_key =~ s/\n|\r//;
$cmd =<<END;
curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/registries' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
  "name": "dockerhub",
  "url": "https://hub.docker.com",
  "insecure": false,
  "type": "docker-hub",
  "description": "Default Harbor Projcet Proxy Cache"
}'
END
$cmd_msg = `$cmd`;
if ($cmd_msg ne '') {
	print("Add dockerhub Registry Error: $cmd_msg");
}

sleep(5);
$cmd =<<END;
curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/projects' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
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
$cmd_msg = `$cmd`;
if ($cmd_msg ne '') {
	print("Create dockerhub Proxy Cache Project Error: $cmd_msg");
}

# Rancher
$cmd = "sudo $home/deploy-devops/rancher/install_rancher.pl";
print("\nInstall Rancher..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<$wait_sec) {
	print('.');
	$cmd_msg = `nc -z -v $rancher_url 6443 2>&1`;
	# Connection to 10.20.0.71 6443 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
if ($isChk) {
	print("Failed to deploy Rancher!\n");
	print("-----\n$cmd_msg-----\n");
	exit;
}
else {
	print("OK!\n");
	print("Successfully deployed Rancher!\n");
}

print("\nThe deployment of Gitlab / Rancher / Harbor / NFS services has been completed, These services URL are: \n");
print("GitLab - http://$gitlab_ip/\n");
print("Rancher - https://$rancher_url:6443/\n");
print("Harbor - https://$harbor_ip:5443/\n");
print("\nplease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 4. to continue.\n\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}