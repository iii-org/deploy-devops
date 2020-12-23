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
print("Deploy Gitlab..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

#55f53640bc5e: gitlab/gitlab-ce:12.10.6-ce.0: running
$isChk=1;
$count=0;
$cmd = "sudo docker ps --format \"{{.ID}}: {{.Image}}: {{.State}}\" | grep \"gitlab\"";
while($isChk && $count<5) {
	print('.');
	$isChk = 0;
	$line = `$cmd`;
	$line =~ s/\n|\r//g;
	if ($line eq '') {
		$isChk ++;
	}
	else {
		($l_id, $l_image, $l_state) = split(/: /, $line);
		if ($l_state ne 'running') {
			print("[$l_image][$l_state]\n");
			$isChk ++;
		}
	}
	$count ++;
	sleep($isChk);
}
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg-----\n");
if ($isChk) {
	print("Failed to deploy GitLab!\n");
	exit;	
}
else {
	print("Successfully deployed GitLab!\n");
}

# Harbor
$cmd = "sudo $home/deploy-devops/harbor/create_harbor.pl";
print("\nDeploy and Setting harbor server..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");
#e741c0904f5a: goharbor/harbor-jobservice:v2.1.0: running
#cc3c961b5620: goharbor/nginx-photon:v2.1.0: running
#b8cca61a22f1: goharbor/harbor-core:v2.1.0: running
#f8b3a37fde4a: goharbor/redis-photon:v2.1.0: running
#3b413a2d7ad3: goharbor/harbor-registryctl:v2.1.0: running
#eeb1646e63dc: goharbor/harbor-portal:v2.1.0: running
#3264ed9d0b7d: goharbor/harbor-db:v2.1.0: running
#a508a138b9da: goharbor/harbor-log:v2.1.0: running
$isChk=1;
$count=0;
$cmd = "sudo docker ps --format \"{{.ID}}: {{.Image}}: {{.State}}\" | grep \"goharbor\"";
while($isChk && $count<5) {
	print('.');
	$isChk = 0;
	$running = 0;
	foreach $line (split(/\n/, `$cmd`)) {
		($l_id, $l_image, $l_state) = split(/: /, $line);
		if ($l_state ne 'running') {
			print("[$l_image][$l_state]\n");
			$isChk ++;
		}
		else {
			$running ++;
		}
	}
	if ($running<8) {
		$isChk ++;
	}
	$count ++;
	sleep($isChk);
}
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg-----\n");
if ($isChk) {
	print("Failed to deploy harbor!\n");
	exit;	
}
else {
	print("Successfully deployed harbor!\n");
}

# Rancher
$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_rancher.pl";
print("\nInstall rancher..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

#3c3e647bbb5b: rancher/rancher:v2.4.5: running
$isChk=1;
$count=0;
$cmd = "sudo docker ps --format \"{{.ID}}: {{.Image}}: {{.State}}\" | grep \"rancher\"";
while($isChk && $count<5) {
	print('.');
	$isChk = 0;
	$line = `$cmd`;
	$line =~ s/\n|\r//g;
	if ($line eq '') {
		$isChk ++;
	}
	else {
		($l_id, $l_image, $l_state) = split(/: /, $line);
		if ($l_state ne 'running') {
			print("[$l_image][$l_state]\n");
			$isChk ++;
		}
	}
	$count ++;
	sleep($isChk);
}
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg-----\n");
if ($isChk) {
	print("Failed to deploy rancher!\n");
	exit;	
}
else {
	print("Successfully deployed rancher!\n");
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

print("\nThe deployment of Gitlab / Harbor / Rancher / NFS services has been completed, please Read https://github.com/iii-org/deploy-devops/blob/master/README.md to continue.\n\n");
