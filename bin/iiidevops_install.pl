#!/usr/bin/perl
# Install iiidevops script
#
$cmd = "cd ~; wget https://github.com/iii-org/deploy-devops/archive/master.zip";
print("Getting iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo apt install unzip";
$cmd .= "; cd ~; unzip master.zip";
$cmd .= "; cd deploy-devops-master/";
$cmd .= "; chmod a+x bin/*.sh";
$cmd .= "; chmod a+x gitlab/*.pl";
$cmd .= "; chmod a+x harbor/*.pl";
print("Unziping iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "cd ~/deploy-devops-master/; sudo bin/ubuntu20lts_install_docker.sh";
$cmd .= "; docker -v";
print("Install docker..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

print("Please Edit ~/deploy-devops-master/env.pl \n");
