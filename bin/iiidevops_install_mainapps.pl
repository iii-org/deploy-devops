#!/usr/bin/perl
# Install iiidevops master node script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$home = "$Bin/../../";

# GitLab
$cmd = "sudo $home/deploy-devops/gitlab/create_gitlab.pl";
print("Deploy Gitlab..");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<60) {
	print('.');
	$cmd_msg = `nc -z -v $gitlab_url 80 2>&1`;
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
while($isChk && $count<180) {
	print('.');
	$cmd_msg = `nc -z -v $harbor_url 5443 2>&1`;
	# Connection to 10.20.0.71 5443 port [tcp/*] succeeded!
	$isChk = index($cmd_msg, 'succeeded!')<0?1:0;
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


# Rancher
$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_rancher.pl";
print("\nInstall Rancher..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$isChk=1;
$count=0;
while($isChk && $count<120) {
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
print("GitLab - http://$gitlab_url/\n");
print("Rancher - https://$rancher_url:6443/\n");
print("Harbor - https://$harbor_url:5443/\n");
print("\nplease Read https://github.com/iii-org/deploy-devops/blob/master/README.md Step 4. to continue.\n\n");
