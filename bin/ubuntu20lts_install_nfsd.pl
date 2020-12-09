#!/usr/bin/perl
# Install nfs service script
#
$cmd = "sudo apt install nfs-kernel-server -y";
print("Install NFS service Package..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

$cmd = "echo '/iiidevopsNFS *(no_root_squash,rw,sync,no_subtree_check)' |sudo tee -a /etc/exports";
$cmd .= "; sudo mkdir /iiidevopsNFS";
$cmd .= "; sudo chmod 777 /iiidevopsNFS";
$cmd .= "; sudo systemctl restart nfs-kernel-server";
$cmd .= "; sudo showmount -e localhost";
print("Setting & Restart NFS Service..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");

# Create redmine-postgresql folder for redmine-postgresql  
$cmd = "sudo mkdir /iiidevopsNFS/redmine-postgresql";
$cmd .= "; sudo chmod 777 /iiidevopsNFS/redmine-postgresql";
# Create devopsdb folder for DevOps DB  
$cmd .= "; sudo mkdir /iiidevopsNFS/devopsdb";
$cmd .= "; sudo chmod 777 /iiidevopsNFS/devopsdb";
# Create sonarqube folder for SonarQube Server  
$cmd .= "; sudo mkdir /iiidevopsNFS/sonarqube";
$cmd .= "; sudo chmod 777 /iiidevopsNFS/sonarqube";
print("Create iiidevops services folder for NFS service..\n");
$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n-----\n");
