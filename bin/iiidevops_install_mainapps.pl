#!/usr/bin/perl
# Install iiidevops master node script
#
$cmd = "sudo ~/deploy-devops/gitlab/create_gitlab.pl";
print("Deploy Gitlab on Master Node(VM1)..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo ~/deploy-devops/harbor/create_harbor.pl";
print("Deploy and Setting harbor server on Master Node(VM1)..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo ~/deploy-devops/bin/ubuntu20lts_install_rancher.pl";
print("install rancher on Master Node(VM1)..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo ~/deploy-devops/bin/ubuntu20lts_install_nfsd.pl";
print("Install & Setting NFS service on Master Node(VM1)..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

print("Then, please Read https://github.com/iii-org/deploy-devops/blob/master/README.md \n\n");
