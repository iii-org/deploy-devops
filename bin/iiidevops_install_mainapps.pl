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

print("Then, please Read https://github.com/iii-org/deploy-devops/blob/master/README.md \n\n");
