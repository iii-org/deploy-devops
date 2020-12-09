#!/usr/bin/perl
#
# 4 Ubuntu20.04 LTS VM
# 	VM1(iiidevops1, 140.92.4.3): GitLab ce-12.10.6 Server, Harbor 2.1 Server, Rancher Server, NFS Server
#		Storage Path:
#			/gitlab		#GitLab
#			/data		#Harbor
#			/
# 	VM2(iiidevops2, 140.92.4.4): Kubernetes node(control plane + etcd + worker node)
# 	VM3(iiidevops3, 140.92.4.5): Kubernetes node(control plane + etcd + worker node)
# 	VM4(iiidevops4, 140.92.4.6): Kubernetes node(control plane + etcd + worker node)
#
# GitLab External URL gitlab/create_gitlab.pl
$gitlab_url = ""; # Exp. 140.92.4.3 , if empty value then auto using server ip
# Harbor External URL harbor/create_harbor.pl
$harbor_url = ""; # Exp. 140.92.4.3 , if empty value then auto using server ip
# Rancher External URL bin/iiidevops_install_apps.pl
$rancher_url = ""; # Exp. 140.92.4.3 , if empty value then auto using server ip
# NFS IP bin/iiidevops_install_apps.pl
$nfs_ip = "10.20.0.71"; # Exp. 140.92.4.3 
# Postgre root password
$postgres_password = "a717cfa6db4ff07aefef1d81026289b8";
