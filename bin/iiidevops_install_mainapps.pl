#!/usr/bin/perl
# Install iiidevops master node script
#
use FindBin qw($Bin);
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
if (index($cmd_msg, $chk_key)<0) {
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

$cmd = "curl -k --location --request POST 'https://$harbor_ip:5443/api/v2.0/registries'";
$chk_key = 'UNAUTHORIZED!';
$cmd_msg = `$cmd 2>&1`;
#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
if (index($cmd_msg, $chk_key)<0) {
	log_print("Failed to deploy Harbor!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;	
}
log_print("OK!\n");
log_print("Successfully deployed Harbor!\n");


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