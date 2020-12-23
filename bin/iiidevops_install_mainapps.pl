#!/usr/bin/perl
# Install iiidevops master node script
#
use FindBin qw($Bin);

$home = "$Bin/../../";

$cmd = "sudo $home/deploy-devops/gitlab/create_gitlab.pl";
print("Deploy Gitlab..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo $home/deploy-devops/harbor/create_harbor.pl";
print("Deploy and Setting harbor server..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_rancher.pl";
print("install rancher..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo $home/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
print("Install & Setting NFS service..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");


# Display Wait 3 min. message
print("It takes 1 to 3 minutes to deploy Gitlab / Harbor / Rancher / NFS services. Please wait.. \n");

# check deploy status
#localadmin@iiidevops-71:~$ sudo docker ps --format "{{.ID}}: {{.Image}}: {{.State}}"
#3c3e647bbb5b: rancher/rancher:v2.4.5: running
#e741c0904f5a: goharbor/harbor-jobservice:v2.1.0: running
#cc3c961b5620: goharbor/nginx-photon:v2.1.0: running
#b8cca61a22f1: goharbor/harbor-core:v2.1.0: running
#f8b3a37fde4a: goharbor/redis-photon:v2.1.0: running
#3b413a2d7ad3: goharbor/harbor-registryctl:v2.1.0: running
#eeb1646e63dc: goharbor/harbor-portal:v2.1.0: running
#3264ed9d0b7d: goharbor/harbor-db:v2.1.0: running
#a508a138b9da: goharbor/harbor-log:v2.1.0: running
#55f53640bc5e: gitlab/gitlab-ce:12.10.6-ce.0: running
$isChk=1;
while($isChk) {
	$isChk = 0;
	foreach $line (split(/\n/, `sudo docker ps --format "{{.ID}}: {{.Image}}: {{.State}}"`)) {
		($l_id, $l_image, $l_state) = split(/: /, $line);
		if ($l_state ne 'running') {
			print("[$l_image][$l_state]\n");
			$isChk ++;
		}
	}
	sleep($isChk);
}

print("\nThe deployment of Gitlab / Harbor / Rancher / NFS services has been completed, please Read https://github.com/iii-org/deploy-devops/blob/master/README.md \n\n");
