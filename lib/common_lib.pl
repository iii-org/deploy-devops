#!/usr/bin/perl
# common lib
#
use JSON::MaybeXS qw(encode_json decode_json);

# Glbal variable
%hash_rke_cluster_yml = (
	'v1.2.7'=>'cluster_0_yml.tmpl', 
	'v1.1.19'=>'cluster_1_yml.tmpl',
	);

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
		#$v_domain_name = get_domain_name('gitlab');
		$v_port = ($gitlab_domain_name_tls ne '')?32081:32080;
		$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
		$v_cmd = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';
		$v_cmd .= " -q --max-time 5 -I $v_http://localhost:$v_port/users/sign_in";
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
		$v_http = ($sonarqube_domain_name_tls ne '')?'https':'http';
		$v_cmd = ($sonarqube_domain_name_tls ne '')?'curl -k':'curl';
		$v_cmd .= " -q --max-time 5 -I $v_http://$v_domain_name";
		# HTTP/1.1 200 OK
		$v_chk_key = ($sonarqube_domain_name_tls ne '')?'HTTP/2 200':'HTTP/1.1 200';
		# Content-Type: text/html;charset=utf-8
		#$v_chk_key = 'Content-Type: text/html;charset=utf-8';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	elsif ($p_service eq 'iiidevops') {
		$v_domain_name = get_domain_name('iiidevops');
		$v_http = ($iiidevops_domain_name_tls ne '')?'https':'http';
		$v_cmd = ($iiidevops_domain_name_tls ne '')?'curl -k':'curl';
		$v_cmd .= " -q --max-time 5 -I $v_http://$v_domain_name";
		# HTTP/1.1 200 OK
		$v_chk_key = ($iiidevops_domain_name_tls ne '')?'HTTP/2 200':'HTTP/1.1 200';
		# Content-Type: text/html;charset=utf-8
		#$v_chk_key = 'Content-Type: text/html;charset=utf-8';
		$v_cmd_msg = `$v_cmd 2>&1`;
		#log_print("-----\n$v_cmd_msg-----\n");
		$v_status = !(index($v_cmd_msg, $v_chk_key)<0);
	}
	else {
		$v_status = -1;
	}

	return($v_status);
}

# Deploy Mode $deploy_mode = # IP(Default), DNS
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

# Check cert file
sub check_cert_file {
	my ($p_cert_file, $p_dns) = @_;
	my ($v_cmd, $v_cmd_msg, $v_ret, $v_chk_key);
	
	# Get DNS info
	$v_cmd = "openssl x509 -in $p_cert_file -ext subjectAltName -noout";
	$v_cmd_msg = `$v_cmd 2>&1`;
	#X509v3 Subject Alternative Name:
	#    DNS:dev2.iiidevops.org, DNS:gitlab-dev2.iiidevops.org, DNS:harbor-dev2.iiidevops.org, DNS:rancher-dev2.iiidevops.org
	$v_chk_key = (length($p_dns)>0)?"DNS:$p_dns":'DNS:';
	$v_ret = (index($v_cmd_msg, $v_chk_key)>0);
	
	return($v_ret);
}

# Ref - https://support.comodo.com/index.php?/Knowledgebase/Article/View/684/17/how-do-i-verify-that-a-private-key-matches-a-certificate-openssl
# Check cert key file
sub check_key_file {
	my ($p_key_file, $p_cert_file) = @_;
	my ($v_cmd, $v_cmd_msg, $v_ret, $v_key_md5, $v_cert_md5);

	$v_cmd = "openssl rsa -check -noout -in $p_key_file";
	$v_cmd_msg = `$v_cmd 2>&1`;
	#RSA key ok
	$v_ret = (index($v_cmd_msg, 'RSA key ok')>=0);

	if (length($p_cert_file)>0 && $v_ret) {
		$v_key_md5 = `openssl rsa -modulus -noout -in $p_key_file | openssl md5`;
		$v_cert_md5 = `openssl x509 -modulus -noout -in $p_cert_file | openssl md5`;
		$v_ret = ($v_key_md5 eq $v_cert_md5);
	}
	
	return($v_ret);
}

# Check secret tls
sub check_secert_tls {
	my ($p_secert_tls, $p_namespace) = @_;
	my ($cmd_kubectl, $v_namespace, $v_cmd, $v_cmd_msg, $v_ret);
	
	$cmd_kubectl = '/snap/bin/kubectl';
	if (!-e $cmd_kubectl) {
		$cmd_kubectl = '/usr/local/bin/kubectl';
	}

	$v_namespace = ($p_namespace ne '')?'-n '.$p_namespace:'';
	$v_cmd = "$cmd_kubectl get secret $p_secert_tls $v_namespace";
	$v_cmd_msg = `$v_cmd 2>&1`;
	#devops-iiidevops-tls   kubernetes.io/tls   2      12m
	$v_ret = (index($v_cmd_msg, 'kubernetes.io/tls')>0);
	
	return($v_ret);
}

# Call Gitlab API
sub call_gitlab_api {
	my ($p_method, $p_api, $p_data, $p_type) = @_;
	my ($v_msg, $v_domain_name, $v_cmd, $v_curl, $v_http, $v_port);
	
	#$v_domain_name = get_domain_name('gitlab');
	$v_http = ($gitlab_domain_name_tls ne '')?'https':'http';
	$v_port = ($gitlab_domain_name_tls ne '')?32081:32080;
	$v_curl = ($gitlab_domain_name_tls ne '')?'curl -k':'curl';

	$v_cmd = "$v_curl -s --request $p_method '$v_http://localhost:$v_port/api/v4/$p_api' --header 'PRIVATE-TOKEN: $gitlab_private_token'";
	if ($p_type ne '') {
		$v_cmd .= " --header 'Content-Type: $p_type'";
	}
	if ($p_data ne '') {
		$v_cmd .= " -d '$p_data'";
	}
	#print("[$v_cmd]\n");
	$v_msg = `$v_cmd 2>&1`;

	return($v_msg);
}

# Call SonarQube API
sub call_sonarqube_api {
	my ($p_method, $p_api) = @_;
	my ($v_msg, $v_domain_name, $v_cmd, $v_curl, $v_http);
	
	$v_domain_name = get_domain_name('sonarqube');
	$v_http = ($sonarqube_domain_name_tls ne '')?'https':'http';
	$v_curl = ($sonarqube_domain_name_tls ne '')?'curl -k':'curl';

	if ($sonarqube_admin_token eq '' || $sonarqube_admin_token eq 'skip') {
		$v_cmd = "$v_curl -s --request $p_method '$v_http://$v_domain_name/api/$p_api' --header 'Authorization: Basic YWRtaW46YWRtaW4='";
	}
	else {
		$v_cmd = "$v_curl -s -u $sonarqube_admin_token: --request $p_method '$v_http://$v_domain_name/api/$p_api'";
	}
	#print("[$v_cmd]\n");
	$v_msg = `$v_cmd 2>&1`;

	return($v_msg);
}

# Get Image Tag(version)
# $rancher_ver = get_image_tag('rancher/rancher', 'cattle-system');
# $rancher_ver : v2.4.17
#
sub get_image_tag {
	my ($p_image_name, $p_name_space) = @_;
	my ($v_cmd, $v_cmd_msg, $v_ns, $t1, $t2, $t3, $v_tag);
	
	if ($p_image_name eq '') {
		return('ERR_0');
	}
	
	$v_cmd = '/usr/local/bin/kubectl';
	if (!-e $v_cmd) {
		$v_cmd = '/snap/bin/kubectl';
		if (!-e $v_cmd) {
			return('ERR_1');
		}
	}
	$v_ns = ($p_name_space ne '')?"-n '$p_name_space'":'';
	$v_cmd = "$v_cmd describe pod $v_ns | grep Image: | grep '$p_image_name:' | head -1";
	$v_cmd_msg = `$v_cmd 2>&1`;
	$v_cmd_msg =~ s/\n|\r//g;
	if ($v_cmd_msg eq '') {
		return('ERR_2');
	}
	
	#    Image:         rancher/rancher:v2.4.17
	$v_cmd_msg =~ s/( )+/ /g;
	($t1, $t2, $t3) = split(/ /, $v_cmd_msg);
	($t1, $v_tag) = split(/:/, $t3);

	return($v_tag);
}

# Get System Version
#rke : v1.2.7 , v1.1.19
#docker : 19.03.x
#kubectl : { "client" : "v1.18.20",  "server" : "v1.18.17" }
#
sub get_system_ver {
	my ($p_system) = @_;
	my ($cmd, $hash_msg, $t1,$t2,$v_ver);
	
	if ($p_system eq 'rke') {
		$cmd = '/usr/local/bin/rke';
		if (!-e $cmd) {
			return('ERR_1');
		}
		$cmd_msg = `$cmd --version 2>&1`;
		$cmd_msg =~ s/\n|\r//g; 
		#rke version v1.2.7
		if (index($cmd_msg, 'rke')<0) {
			return('ERR_2');
		}
		($t1,$t2,$v_ver) = split(/ /, $cmd_msg);
		$v_valid_ver = '[v1.2.7][v1.1.19]';
		if (index($v_valid_ver, "[$v_ver]")<0) {
			return('ERR_3');
		}
		return($v_ver);
	}
	elsif ($p_system eq 'docker') {
		$cmd = '/usr/bin/docker';
		if (!-e $cmd) {
			return('ERR_1');
		}
		$cmd_msg = `$cmd -v 2>&1`;
		$cmd_msg =~ s/\n|\r//g; 
		#Docker version 19.03.14, build 5eb3275d40
		if (index($cmd_msg, 'Docker version')<0) {
			return('ERR_2');
		}
		($t1,$t2,$v_ver) = split(/ /, $cmd_msg);
		$v_ver =~ s/,//g;
		return($v_ver);
	}
	elsif ($p_system eq 'kubectl') {
		$cmd = '/usr/local/bin/kubectl';
		if (!-e $cmd) {
			$cmd = '/snap/bin/kubectl';
			if (!-e $cmd) {
				return('ERR_1');
			}
		}
		$cmd_msg = `$cmd version -o json 2>&1`;
		$cmd_msg =~ s/\n|\r//g; 
		#{
		#  "clientVersion": {
		#    "gitVersion": "v1.18.20",
		#  },
		#  "serverVersion": {
		#    "gitVersion": "v1.18.17",
		#  }
		#}
		if (index($cmd_msg, 'clientVersion')<0) {
			return('ERR_2');
		}
		return($cmd_msg);
	}

	return('ERR_0');
}

# Get CPU Information from /proc/cpuinfo
#
sub get_cpuinfo {
	my ($p_item) = @_;
	my ($cmd, $cmd_msg, $t1,$t2,$v_ans);
	
	if ($p_item eq 'cores') {
		$v_ans = `grep -c -P '^processor\\s+:' /proc/cpuinfo`;
		$v_ans =~ s/\n|\r//g;
		return($v_ans);
	}
	$cmd_msg = `grep -m 1 -P '^$p_item\\s+:' /proc/cpuinfo`;
	$cmd_msg =~ s/\n|\r//g;
	if ($cmd_msg ne '') {
		($t1, $v_ans) = split(/: /, $cmd_msg);
		if (index($t1, $p_item)<0) {
			return('ERR_2');
		}
		return($v_ans);
	}

	return('ERR_0');
}

# Get K8s deployment info
# $pod_num = get_k8sdeploy('Replicas', 'devopsapi');
sub get_k8sdeploy {
	my ($p_item, $p_deployname) = @_;
	my ($cmd_kubectl, $cmd, $cmd_msg, $t1,$t2,$v_ans);

	$cmd_kubectl = '/snap/bin/kubectl';
	if (!-e $cmd_kubectl) {
		$cmd_kubectl = '/usr/local/bin/kubectl';
	}
	if (!-e $cmd_kubectl) {
		return('ERR_1');
	}

	if ($p_item eq 'Replicas') {
		$cmd_msg = `$cmd_kubectl describe deploy $p_deployname | grep '$p_item:'`;
		$cmd_msg =~ s/\n|\r//g;
		#Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
		$cmd_msg =~ s/( )+/ /g;
		($t1,$v_ans,$t2) = split(/ /,$cmd_msg);
		if ($t2 ne 'desired') {
			return('ERR_2');
		}
		return($v_ans);
	}
	
	return('ERR_0');
}

# Check service IP port
sub chk_svcipport {
	my ($p_ip, $p_port, $p_keyword) = @_;
	my ($v_msg);
	
	$p_keyword = ($p_keyword eq '')?'succeeded':$p_keyword;
	$v_msg = `nc -z -v $p_ip $p_port 2>&1`;
	
	return(index($v_msg, $p_keyword)>=0);
}

# url encode / decode
# Ref - https://stackoverflow.com/questions/4510550/using-perl-how-do-i-decode-or-create-those-encodings-on-the-web
sub url_encode {
	my ($p_url) = @_;
	
	$p_url =~ s/([^^A-Za-z0-9\-_.!~*'()])/ sprintf "%%%02x", ord $1 /eg;
	
	return($p_url);
}
sub url_decode {
	my ($p_url) = @_;
	
	$p_url =~ s/%([A-Fa-f\d]{2})/chr hex $1/eg;
	
	return($p_url);
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