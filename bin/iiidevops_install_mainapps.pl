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

$cmd = "sudo mkdir -p $data_dir";
$cmd_msg = `$cmd 2 >&1`;
if ($cmd_msg ne '') {
	print("Create Data Dir [$data_dir] error!\n$cmd_msg\n-----\n");
	exit;
}


$home = "$Bin/../../";

# GitLab
$cmd = "sudo $home/deploy-devops/gitlab/create_gitlab.pl";
print("Deploy Gitlab..");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<$wait_sec) {
	print('.');
	$cmd_msg = `nc -z -v $gitlab_ip 80 2>&1`;
	# Connection to 10.20.0.71 80 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
	$count ++;
	sleep($isChk);
}
if ($isChk) {
	print("Failed to deploy GitLab!\n");
	print("-----\n$cmd_msg-----\n");
	exit;	
}
else {
	print("OK!\n");
#	print("-----\n$cmd_msg-----\n");
	print("Successfully deployed GitLab!\n");
}

# Harbor
$cmd = "sudo $home/deploy-devops/harbor/create_harbor.pl";
print("\nDeploy and Setting Harbor server..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<$wait_sec) {
	print('.');
	$cmd_msg = `curl -k --location --request POST 'https://$harbor_url:5443/api/v2.0/registries' 2>&1`;
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
curl -k --location --request POST 'https://$harbor_url:5443/api/v2.0/registries' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
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
curl -k --location --request POST 'https://$harbor_url:5443/api/v2.0/projects' --header 'Authorization: Basic $harbor_key' --header 'Content-Type: application/json' --data-raw '{
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
$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_rancher.pl";
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
#	print("-----\n$cmd_msg-----\n");
	print("Successfully deployed Rancher!\n");
}

# NFS
$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
print("\nInstall & Setting NFS service..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");
$cmd = "showmount -e $nfs_ip";
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg-----\n");
if (index($cmd_msg, '/iiidevopsNFS')<0) {
	print("NFS configuration failed!\n");
	exit;	
}

print("\nThe deployment of Gitlab / Rancher / Harbor / NFS services has been completed, These services URL are: \n");
print("GitLab - http://$gitlab_ip/\n");
print("Rancher - https://$rancher_url:6443/\n");
print("Harbor - https://$harbor_url:5443/\n");
print("\nplease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 4. to continue.\n\n");
