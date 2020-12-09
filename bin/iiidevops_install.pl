#!/usr/bin/perl
# Install iiidevops script
#
$cmd = "cd ~; wget https://github.com/iii-org/deploy-devops/archive/master.zip";
print("Getting iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
#print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo apt-get install unzip nfs-common -y";
$cmd .= "; cd ~; unzip master.zip";
$cmd .= "; cd deploy-devops-master/";
$cmd .= "; chmod a+x bin/*.sh";
$cmd .= "; chmod a+x gitlab/*.pl";
$cmd .= "; chmod a+x harbor/*.pl";
print("Unziping iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo apt-get update -y ";
$cmd .= "; sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y ";
$cmd .= "; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ";
$cmd .= "; sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" "; 
$cmd .= "; sudo apt-get update -y ";
$cmd .= "; sudo apt-get install docker-ce docker-ce-cli containerd.io -y ";
$cmd .= "; usermod -aG docker \$SUDO_USER ";
$cmd .= "; docker -v";
print("Install docker..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo snap install kubectl --classic";
print("Install kubectl..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

print("Please Edit ~/deploy-devops-master/env.pl \n\n");
