#!/usr/bin/perl
# common lib
#

# Check service status.
# service : kubernetes, rancher, gitlab, redmine, harbor, sonarqube, iiidevops
sub get_service_status {
	my ($p_service) = @_;
	my ($v_status, $v_cmd, $v_cmd_msg, $v_chk_key, $v_isHealthy, $v_domain_name, $v_port, $v_http, @arr_msg);
	
	if ($p_service eq 'kubernetes') {
		$v_cmd = "kubectl get componentstatus";
		#NAME                 STATUS    MESSAGE             ERROR
		#scheduler            Healthy   ok
		#controller-manager   Healthy   ok
		#etcd-0               Healthy   {"health":"true"}
		$v_chk_key = 'Healthy';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		#$v_cmd_msg =~  s/\e\[[\d;]*[a-zA-Z]//g; # Remove ANSI color
		@arr_msg = split("\n", $v_cmd_msg);
		$v_isHealthy = grep{ /$v_chk_key/} @arr_msg;
		$v_status = !($v_isHealthy<3);	
	}
	elsif ($p_service eq 'rancher') {
		$v_domain_name = get_domain_name('rancher');
		$v_cmd = "curl -k --max-time 5 --location --request GET 'https://$v_domain_name/v3'";
		#curl -k --location --request GET 'https://10.20.0.37:31443/v3'
		#{"type":"error","status":"401","message":"must authenticate"} 
		# 2nd method:
		#kubectl -n cattle-system rollout status deploy/rancher
		#deployment "rancher" successfully rolled out
		$v_chk_key = 'must authenticate';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'gitlab') {
		$v_domain_name = get_domain_name('gitlab');
		#$v_port = (uc($deploy_mode) ne 'IP')?80:32080;
		$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
		$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';
		$v_cmd .= " -q --max-time 5 -I $v_http://$v_domain_name/users/sign_in";
		#HTTP/1.1 200 OK , HTTP/2 200
		$v_chk_key = ($gitlab_domain_name_tls ne '')?'HTTP/2 200':'HTTP/1.1 200';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'redmine') {
		$v_domain_name = get_domain_name('redmine');
		$v_http = ($redmine_domain_name_tls ne '')?'https':'http';
		$v_cmd = ($redmine_domain_name_tls ne '')?'curl -k':'curl';
		$v_cmd .= " -q --max-time 5 -I $v_http://$v_domain_name";
		# HTTP/1.1 200 OK
		$v_chk_key = ($redmine_domain_name_tls ne '')?'HTTP/2 200':'HTTP/1.1 200';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'harbor') {
		$v_domain_name = get_domain_name('harbor');
		$v_cmd = "curl -k --max-time 5 --location --request POST 'https://$v_domain_name/api/v2.0/registries'";
		#{"errors":[{"code":"UNAUTHORIZED","message":"UnAuthorized"}]}
		$v_chk_key = 'UNAUTHORIZED';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'sonarqube') {
		$v_domain_name = get_domain_name('sonarqube');
		$v_cmd = "curl -q --max-time 5 -I http://$v_domain_name";
		# Content-Type: text/html;charset=utf-8
		$v_chk_key = 'Content-Type: text/html;charset=utf-8';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'iiidevops') {
	}
	else {
		$v_status = -1;
	}

	return($v_status);
}

# Deploy Mode $deploy_mode = # IP(Default), DNS, nip.io, xip.io
# $p_service : rancher, gitlab, redmine, harbor, sonarqube, iiidevops
# Exp.
#   IP : 10.20.0.73
#		rancher		10.20.0.73:31443
#		gitlab		10.20.0.73:32080
#		redmine		10.20.0.73:32748
#		harbor		10.20.0.73:32443
#		sonarqube	10.20.0.73:31910
#		iiidevops	10.20.0.73:30775
#	DNS : 
#		rancher		rancher.iiidevops.org
#		gitlab		gitlab.iiidevops.org
#		redmine		redmine.iiidevops.org
#		harbor		harbor.iiidevops.org
#		sonarqube	sonarqube.iiidevops.org
#		iiidevops	www.iiidevops.org
#	nip.io
#		rancher		rancher.iiidevops.10.20.0.73.nip.io
#		gitlab		gitlab.iiidevops.10.20.0.73.nip.io
#		redmine		redmine.iiidevops.10.20.0.73.nip.io
#		harbor		harbor.iiidevops.10.20.0.73.nip.io
#		sonarqube	sonarqube.iiidevops.10.20.0.73.nip.io
#		iiidevops	iiidevops.10.20.0.73.nip.io
#	xip.io
#		rancher		rancher.iiidevops.10.20.0.73.xip.io
#		gitlab		gitlab.iiidevops.10.20.0.73.xip.io
#		redmine		redmine.iiidevops.10.20.0.73.xip.io
#		harbor		harbor.iiidevops.10.20.0.73.xip.io
#		sonarqube	sonarqube.iiidevops.10.20.0.73.xip.io
#		iiidevops	iiidevops.10.20.0.73.xip.io
#
sub get_domain_name {
	my ($p_service) = @_;
	my ($v_domain_name);
	
	$v_domain_name = '';
	if (uc($deploy_mode) eq 'DNS') {
		if ($p_service eq 'rancher') {
			$v_domain_name = $rancher_domain_name;
		}
		elsif ($p_service eq 'gitlab') {
			$v_domain_name = $gitlab_domain_name;
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = $redmine_domain_name;
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = $harbor_domain_name;
		}
		elsif ($p_service eq 'sonarqube') {
			$v_domain_name = $sonarqube_domain_name;
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = $iiidevops_domain_name;
		}
	}
	elsif (lc($deploy_mode) eq 'nip.io') {
		if ($p_service eq 'rancher') {
			$v_domain_name = 'rancher.iiidevops.'.$rancher_ip.'.nip.io';
		}
		elsif ($p_service eq 'gitlab') {
			$v_domain_name = 'gitlab.iiidevops.'.$gitlab_ip.'.nip.io';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = 'redmine.iiidevops.'.$redmine_ip.'.nip.io';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = 'harbor.iiidevops.'.$harbor_ip.'.nip.io';
		}
		elsif ($p_service eq 'sonarqube') {
			$v_domain_name = 'sonarqube.iiidevops.'.$sonarqube_ip.'.nip.io';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = 'iiidevops.'.$iiidevops_ip.'.nip.io';
		}
	}
	elsif (lc($deploy_mode) eq 'xip.io') {
		if ($p_service eq 'rancher') {
			$v_domain_name = 'rancher.iiidevops.'.$rancher_ip.'.xip.io';
		}
		elsif ($p_service eq 'gitlab') {
			$v_domain_name = 'gitlab.iiidevops.'.$gitlab_ip.'.xip.io';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = 'redmine.iiidevops.'.$redmine_ip.'.xip.io';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = 'harbor.iiidevops.'.$harbor_ip.'.xip.io';
		}
		elsif ($p_service eq 'sonarqube') {
			$v_domain_name = 'sonarqube.iiidevops.'.$sonarqube_ip.'.xip.io';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = 'iiidevops.'.$iiidevops_ip.'.xip.io';
		}
	}
	else {
		# IP(Default)
		if ($p_service eq 'rancher') {
			$v_domain_name = $rancher_ip.':31443';
		}
		elsif ($p_service eq 'gitlab') {
			$v_domain_name = $gitlab_ip.':32080';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = $redmine_ip.':32748';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = $harbor_ip.':32443';
		}
		elsif ($p_service eq 'sonarqube') {
			$v_domain_name = $sonarqube_ip.':31910';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = $iiidevops_ip.':30775';
		}
	}
	
	return($v_domain_name);
}

# Check secret tls
sub check_secert_tls {
	my ($p_secert_tls, $p_namespace) = @_;
	my ($cmd_kubectl, $v_namespace, $v_cmd, $v_cmd_msg, $v_ret);
	
	$cmd_kubectl = '/snap/bin/kubectl';
	if (!-e $$cmd_kubectl) {
		$cmd_kubectl = '/usr/local/bin/kubectl';
	}

	$v_namespace = ($p_namespace ne '')?'-n '.$p_namespace:'';
	$v_cmd = "$cmd_kubectl get secret $p_secert_tls $v_namespace";
	$v_cmd_msg = `$v_cmd 2>&1`;
	#devops-iiidevops-tls   kubernetes.io/tls   2      12m
	$v_ret = (index($v_cmd_msg, 'kubernetes.io/tls')>0);
	
	return($v_ret);
}

# $logfile
sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}

1;