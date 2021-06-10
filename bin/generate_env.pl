#!/usr/bin/perl
# Generate iiidevops env information script
#
use Socket;
use Sys::Hostname;
use FindBin qw($Bin);
use Digest::SHA qw(sha1_hex);

$p_config = "$Bin/../env.pl";
$p_config_bak = $p_config.".bak";
$p_config_tmpl = $p_config.".tmpl";
if (!-e $p_config_tmpl) {
	print("The template file [$p_config_tmpl] does not exist!\n");
	exit;
}

$p_config_ans = $p_config.".ans";
$p_config_ans_tmpl = $p_config_ans.".tmpl";
if (!-e $p_config_ans_tmpl) {
	print("The template file [$p_config_ans_tmpl] does not exist!\n");
	exit;
}
$ans_tmpl = `cat $p_config_ans_tmpl`;
if (-e $p_config_ans) {
	require($p_config_ans);
}

$nfs_dir = defined($nfs_dir)?$nfs_dir:'/iiidevopsNFS';

if (-e "$nfs_dir/deploy-config/env.pl") {
	$cmd_msg = `rm -f $p_config; ln -s $nfs_dir/deploy-config/env.pl $p_config`; 
}
if (-e "$nfs_dir/deploy-config/env.pl.ans") {
	$cmd_msg = `rm -f $p_config_ans; ln -s $nfs_dir/deploy-config/env.pl.ans $p_config_ans`; 
}

# Set the specified key value
if (defined($ARGV[0])) {
	if (index($ans_tmpl, '{{ask_'.$ARGV[0].'}}')<0 && lc($ARGV[0]) ne 'convert') {
		print("The specified key: [$ARGV[0]] is unknown!\n");
		exit;
	}
}

# convert env.pl.ans to env.pl
if ($ARGV[0] eq 'convert') {
	convert();
	exit;
}

# 0. get host IP
$host = hostname();
$host_ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));

# 1.1 Set $vm1_ip
#\$ask_vm1_ip = '{{ask_vm1_ip}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'vm1_ip') {
	if (!defined($ARGV[1])) {
		$ask_vm1_ip = (defined($ask_vm1_ip) && $ask_vm1_ip ne '{{ask_vm1_ip}}' && $ask_vm1_ip ne '')?$ask_vm1_ip:$host_ip;
		$question = "Q1.1 Please enter the base service IP?($ask_vm1_ip)";
		$isAsk = 1;
		while($isAsk) {
			$ans_ip = prompt_for_input($question);
			$ans_ip = ($ans_ip eq '')?$ask_vm1_ip:$ans_ip;
			if ($ans_ip ne '' && index($ans_ip, '127.')!=0) {
				$ask_vm1_ip = $ans_ip;
				$isAsk = 0;
			}
			else {
				print("A1.1 This IP $ans_ip is not allowed, please re-enter!\n");
			}
		}
	}
	else {
		$ask_vm1_ip = $ARGV[1];
	}
	$answer = "A1.1 Set [$ask_vm1_ip] for Base Service";
	print ("$answer\n\n");
	if ($ask_vm1_ip ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_vm1_ip;
			require($p_config_ans);
			$ask_vm1_ip=$tmp;
		}
		write_ans();
	}
}

# 1.2 Set $vm2_ip
#\$ask_vm2_ip = '{{ask_vm2_ip}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'vm2_ip') {
	if (!defined($ARGV[1])) {
		$ask_vm2_ip = (defined($ask_vm2_ip) && $ask_vm2_ip ne '{{ask_vm2_ip}}' && $ask_vm2_ip ne '')?$ask_vm2_ip:$ask_vm1_ip;
		$question = "Q1.2 Please enter other services running in K8s IP (Rancher, Gitlab, Redmine, Harbor, Sonarqube, III DevOps)?($ask_vm2_ip)";
		$isAsk = 1;
		while($isAsk) {
			$ans_ip = prompt_for_input($question);
			$ans_ip = ($ans_ip eq '')?$ask_vm2_ip:$ans_ip;
			if ($ans_ip ne '' && index($ans_ip, '127.')!=0) {
				$ask_vm2_ip = $ans_ip;
				$isAsk = 0;
			}
			else {
				print("A1.2 This IP $ans_ip is not allowed, please re-enter!\n");
			}
		}
	}
	else {
		$ask_vm2_ip = $ARGV[1];
	}
	$answer = "A1.2 Set [$ask_vm2_ip] for other services";
	print ("$answer\n\n");
	if ($ask_vm2_ip ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_vm2_ip;
			require($p_config_ans);
			$ask_vm2_ip=$tmp;
		}
		write_ans();
	}
}

# 1.3 Set $nfs_ip
#\$ask_nfs_ip = '{{ask_nfs_ip}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'nfs_ip') {
	if (!defined($ARGV[1])) {
		$ask_nfs_ip = (defined($ask_nfs_ip) && $ask_nfs_ip ne '{{ask_nfs_ip}}' && $ask_nfs_ip ne '')?$ask_nfs_ip:$ask_vm1_ip;
		$question = "Q1.3 Please enter NFS service IP?($ask_nfs_ip)";
		$isAsk = 1;
		while($isAsk) {
			$ans_ip = prompt_for_input($question);
			$ans_ip = ($ans_ip eq '')?$ask_nfs_ip:$ans_ip;
			if ($ans_ip ne '' && index($ans_ip, '127.')!=0) {
				$ask_nfs_ip = $ans_ip;
				$isAsk = 0;
			}
			else {
				print("A1.3 This IP $ans_ip is not allowed, please re-enter!\n");
			}
		}
	}
	else {
		$ask_nfs_ip = $ARGV[1];
	}
	$answer = "A1.3 Set [$ask_nfs_ip] for NFS service";
	print ("$answer\n\n");
	if ($ask_nfs_ip ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_nfs_ip;
			require($p_config_ans);
			$ask_nfs_ip=$tmp;
		}
		write_ans();
	}
}

# 1.4 Set $nfs_dir
#\$ask_nfs_dir = '{{ask_nfs_dir}}';
$ask_nfs_dir = ($ask_nfs_dir eq '')?$nfs_dir:$ask_nfs_dir;
if (!defined($ARGV[0]) || $ARGV[0] eq 'nfs_dir') {
	if (!defined($ARGV[1])) {
		$ask_nfs_dir = (defined($ask_nfs_dir) && $ask_nfs_dir ne '{{ask_nfs_dir}}' && $ask_nfs_dir ne '')?$ask_nfs_dir:$nfs_dir;
		$question = "Q1.4 Please enter NFS shared dir?($ask_nfs_dir)";
		$isAsk = 1;
		while($isAsk) {
			$ans_dir = prompt_for_input($question);
			$ans_dir = ($ans_dir eq '')?$ask_nfs_dir:$ans_dir;
			if ($ans_dir ne '') {
				$ask_nfs_dir = $ans_dir;
				$isAsk = 0;
			}
			else {
				print("A1.4 This shared dir $ans_dir is not allowed, please re-enter!\n");
			}
		}
	}
	else {
		$ask_nfs_dir = $ARGV[1];
	}
	$answer = "A1.4 Set [$ask_nfs_dir] for NFS shared dir";
	print ("$answer\n\n");
	if ($ask_nfs_dir ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_nfs_dir;
			require($p_config_ans);
			$ask_nfs_dir=$tmp;
		}
		write_ans();
	}
}

# 2.1 set III-DevOps installation version
#\$ask_iiidevops_ver = '{{ask_iiidevops_ver}}';
$ver_str = '[1] [develop]';
if (!defined($ARGV[0]) || $ARGV[0] eq 'iiidevops_ver') {
	if (!defined($ARGV[1])) {
		$ask_iiidevops_ver = (defined($ask_iiidevops_ver) && $ask_iiidevops_ver ne '{{ask_iiidevops_ver}}' && $ask_iiidevops_ver ne '')?$ask_iiidevops_ver:'';
		if ($ask_iiidevops_ver ne '') {
			$question = "Q2.1 Do you want to change III-DevOps installation version: $ask_iiidevops_ver ?(y/N)";
			$answer = "A2.1 III-DevOps installation version: $ask_iiidevops_ver";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$ask_iiidevops_ver = ($ask_iiidevops_ver eq '')?'1':$ask_iiidevops_ver;
			$question = "Q2.1 Please enter the III-DevOps installation version(Options:$ver_str)?($ask_iiidevops_ver)";
			$ask_iiidevops_ver = prompt_for_input($question);
			$isAsk = (index($ver_str, '['.$ask_iiidevops_ver.']')<0);
			if ($isAsk) {
				print("A2.1 The version is wrong, please re-enter!\n");
			}
			else {
				$answer = "A2.1 III-DevOps installation version: $ask_iiidevops_ver OK!";
			}
		}
	}
	else {
		$ask_iiidevops_ver = $ARGV[1];
		$answer = "A2.1 III-DevOps installation version: $ask_iiidevops_ver OK!";
	}
	print ("$answer\n\n");
	if ($ask_iiidevops_ver ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_iiidevops_ver;
			require($p_config_ans);
			$ask_iiidevops_ver=$tmp;
		}
		write_ans();
	}
}

# 2.2 set Deploy Mode # IP(Default), DNS
#\$ask_deploy_mode = '{{ask_deploy_mode}}';
$mode_str = '[IP] [DNS]';
if (!defined($ARGV[0]) || $ARGV[0] eq 'deploy_mode') {
	if (!defined($ARGV[1])) {
		$ask_deploy_mode = (defined($ask_deploy_mode) && $ask_deploy_mode ne '{{ask_deploy_mode}}' && $ask_deploy_mode ne '')?$ask_deploy_mode:'';
		if ($ask_deploy_mode ne '') {
			$question = "Q2.2 Do you want to change the deployment mode: $ask_deploy_mode ?(y/N)";
			$answer = "A2.2 Deployment mode: $ask_deploy_mode";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$ask_deploy_mode = ($ask_deploy_mode eq '')?'IP':$ask_deploy_mode;
			$question = "Q2.2 Please enter the deployment mode (Options:$mode_str)?($ask_deploy_mode)";
			$ask_deploy_mode = prompt_for_input($question);
			$isAsk = (index($mode_str, '['.$ask_deploy_mode.']')<0);
			if ($isAsk) {
				print("A2.2 The deployment mode is wrong, please re-enter!\n");
			}
			else {
				$answer = "A2.2 Set the deployment mode: $ask_deploy_mode OK!";
			}
		}
	}
	else {
		$ask_deploy_mode = $ARGV[1];
		$answer = "A2.2 Set the deployment mode: $ask_deploy_mode OK!";
	}
	print ("$answer\n\n");
	if ($ask_deploy_mode ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_deploy_mode;
			require($p_config_ans);
			$ask_deploy_mode=$tmp;
		}
		write_ans();
	}
}

# 2.3 set Services Domain Name
# gitlab_domain_name, harbor_domain_name, redmine_domain_name, sonarqube_domain_name, iiidevops_domain_name
if (!defined($ARGV[0]) && $ask_deploy_mode eq 'DNS') {
	$question = "Q2.3 Do you want to change services domain name setting?(y/N)";
	$answer = "A2.3 Skip change services domain name setting!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk = 0;
}
if ($isAsk) {
	require($Bin.'/generate_env_domainname.pl');
}

# 3. set GitLab root password
#\$ask_gitlab_root_password = '{{ask_gitlab_root_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'gitlab_root_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_gitlab_root_password) && $ask_gitlab_root_password ne '{{ask_gitlab_root_password}}' && $ask_gitlab_root_password ne '')?$ask_gitlab_root_password:'';
		if ($password1 ne '') {
			$question = "Q3. Do you want to change GitLab root password?(y/N)";
			$answer = "A3. Skip Set GitLab root password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');
		}	
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q3. Please enter the GitLab root password:(Must be 8-20 characters long with at least 1 uppercase, 1 lowercase and 1 number)";
			$password1 = prompt_for_password($question);
			$question = "Q3. Please re-enter the GitLab root password:";
			$password2 = prompt_for_password($question);
			$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			if ($isAsk) {
				print("A3. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A3. Set GitLab root password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A3. Set GitLab root password OK!";
	}
	$ask_gitlab_root_password = $password1;
	print ("$answer\n\n");
	if ($ask_gitlab_root_password ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_gitlab_root_password;
			require($p_config_ans);
			$ask_gitlab_root_password=$tmp;
		}
		write_ans();
	}
}

# Set same_passwd for another password 
$same_passwd = $ask_gitlab_root_password;


# 4. set GitLab Token
#\$ask_gitlab_private_token = '{{ask_gitlab_private_token}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'gitlab_private_token') {
	if (!defined($ARGV[1])) {
		$ask_gitlab_private_token = (defined($ask_gitlab_private_token) && $ask_gitlab_private_token ne '{{ask_gitlab_private_token}}' && $ask_gitlab_private_token ne '' && lc($ask_gitlab_private_token) ne 'skip')?$ask_gitlab_private_token:'';
		if ($ask_gitlab_private_token ne '') {
			$question = "Q4. Do you want to change GitLab Token?(y/N)";
			$answer = "A4. Skip Set GitLab Token!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q4. Please enter the GitLab Token:(If your GitLab has not been set up, please enter 'SKIP')";
			$ask_gitlab_private_token = prompt_for_input($question);
			$isAsk = ($ask_gitlab_private_token eq '');
			if ($isAsk) {
				print("A4. The Token is empty, please re-enter!\n");
			}
			else {
				$answer = "A4. Set GitLab Token OK!";
			}
		}
	}
	else {
		$ask_gitlab_private_token = $ARGV[1];
		$answer = "A4. Set GitLab Token OK!";
	}
	print ("$answer\n\n");
	if ($ask_gitlab_private_token ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_gitlab_private_token;
			require($p_config_ans);
			$ask_gitlab_private_token=$tmp;
		}
		write_ans();
	}
}

# 5. set Rancher admin password
#\$ask_rancher_admin_password = '{{ask_rancher_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'rancher_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_rancher_admin_password) && $ask_rancher_admin_password ne '{{ask_rancher_admin_password}}' && $ask_rancher_admin_password ne '')?$ask_rancher_admin_password:'';
		if ($password1 ne '') {
			$question = "Q5. Do you want to change Rancher admin password?(y/N)";
			$answer = "A5. Skip Set Rancher admin password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q5. Please enter the Rancher admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q5. Please re-enter the Rancher admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A5. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A5. Set Rancher admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A5. Set Rancher admin password OK!";
	}
	$ask_rancher_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_rancher_admin_password ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_rancher_admin_password;
			require($p_config_ans);
			$ask_rancher_admin_password=$tmp;
		}
		write_ans();
	}
}

# 6.1 set Redmine admin password
#\$ask_redmine_admin_password = '{{ask_redmine_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'redmine_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_redmine_admin_password) && $ask_redmine_admin_password ne '{{ask_redmine_admin_password}}' && $ask_redmine_admin_password ne '')?$ask_redmine_admin_password:'';
		if ($password1 ne '') {
			$question = "Q6.1 Do you want to change Redmine admin password?(y/N)";
			$answer = "A6.1 Skip Set Redmine admin password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q6.1 Please enter the Redmine admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q6.1 Please re-enter the Redmine admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A6.1 The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A6.1 Set Redmine admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A6.1 Set Redmine admin password OK!";
	}
	$ask_redmine_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_redmine_admin_password ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_redmine_admin_password;
			require($p_config_ans);
			$ask_redmine_admin_password=$tmp;
		}
		write_ans();
	}
}

# 6.2 set Redmine API key
#\$ask_redmine_api_key = '{{ask_redmine_api_key}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'redmine_api_key') {
	if (!defined($ARGV[1])) {
		$ask_redmine_api_key = (defined($ask_redmine_api_key) && $ask_redmine_api_key ne '{{ask_redmine_api_key}}' && $ask_redmine_api_key ne '')?$ask_redmine_api_key:'';
		if ($ask_redmine_api_key ne '') {
			$question = "Q6.2 Do you want to change Redmine API key?(y/N)";
			$answer = "A6.2 Skip Set Redmine API key!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		if ($isAsk) {
			$ask_redmine_api_key = sha1_hex(random_password(20));
			$answer = "A6.2 Set Redmine API key OK!";
		}
	}
	else {
		$value = (lc($ARGV[1]) eq 'auto')?sha1_hex(random_password(20)):$ARGV[1];
		$ask_redmine_api_key = $value;
		$answer = "A6.2 Set Redmine API key OK!";
	}
	print ("$answer\n\n");
	if ($ask_redmine_api_key ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_redmine_api_key;
			require($p_config_ans);
			$ask_redmine_api_key=$tmp;
		}
		write_ans();
	}
}

# 7.1 set Sonarqube admin password
#\$ask_sonarqube_admin_passwd = '{{ask_sonarqube_admin_passwd}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'sonarqube_admin_passwd') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_sonarqube_admin_passwd) && $ask_sonarqube_admin_passwd ne '{{ask_sonarqube_admin_passwd}}' && $ask_sonarqube_admin_passwd ne '')?$ask_sonarqube_admin_passwd:'';
		if ($password1 ne '') {
			$question = "Q7.1 Do you want to change Sonarqube admin password?(y/N)";
			$answer = "A7.1 Skip Set Sonarqube admin password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q7.1 Please enter the Sonarqube admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q7.1 Please re-enter the Sonarqube admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A7.1 The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A7.1 Set Sonarqube admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A7.1 Set Sonarqube admin password OK!";
	}
	$ask_sonarqube_admin_passwd = $password1;
	print ("$answer\n\n");
	if ($ask_sonarqube_admin_passwd ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_sonarqube_admin_passwd;
			require($p_config_ans);
			$ask_sonarqube_admin_passwd=$tmp;
		}
		write_ans();
	}
}

# 7.2 set Sonarqube Admin Token
#\$sonarqube_admin_token = '{{ask_sonarqube_admin_token}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'sonarqube_admin_token') {
	if (!defined($ARGV[1])) {
		$ask_sonarqube_admin_token = (defined($ask_sonarqube_admin_token) && $ask_sonarqube_admin_token ne '{{ask_sonarqube_admin_token}}' && $ask_sonarqube_admin_token ne '' && lc($ask_sonarqube_admin_token) ne 'skip')?$ask_sonarqube_admin_token:'';
		if ($ask_sonarqube_admin_token ne '') {
			$question = "Q7.2 Do you want to change Sonarqube Admin Token?(y/N)";
			$answer = "A7.2 Skip Set Sonarqube Admin Token!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q7.2 Please enter the Sonarqube Admin Token:(If your Sonarqube has not been set up, please enter 'SKIP')";
			$ask_sonarqube_admin_token = prompt_for_input($question);
			$isAsk = ($ask_sonarqube_admin_token eq '');
			if ($isAsk) {
				print("A7.2 The Token is empty, please re-enter!\n");
			}
			else {
				$answer = "A7.2 Set Sonarqube Admin Token OK!";
			}
		}
	}
	else {
		$ask_sonarqube_admin_token = $ARGV[1];
		$answer = "A7.2 Set Sonarqube Admin Token OK!";
	}
	print ("$answer\n\n");
	if ($ask_sonarqube_admin_token ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_sonarqube_admin_token;
			require($p_config_ans);
			$ask_sonarqube_admin_token=$tmp;
		}
		write_ans();
	}
}

# 8. set Harbor admin password
#\$ask_harbor_admin_password = '{{ask_harbor_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'harbor_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_harbor_admin_password) && $ask_harbor_admin_password ne '{{ask_harbor_admin_password}}' && $ask_harbor_admin_password ne '')?$ask_harbor_admin_password:'';
		if ($password1 ne '') {
			$question = "Q8. Do you want to change Harbor admin password?(y/N)";
			$answer = "A8. Skip Set Harbor admin password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q8. Please enter the Harbor admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q8. Please re-enter the Harbor admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A8. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A8. Set Harbor admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A8. Set Harbor admin password OK!";
	}
	$ask_harbor_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_harbor_admin_password ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_harbor_admin_password;
			require($p_config_ans);
			$ask_harbor_admin_password=$tmp;
		}
		write_ans();
	}
}

# 9. set III-DevOps settings(Core)
require($Bin.'/generate_env_iiidevops.pl');

# 10a. Automatically generate password
#\$ask_auto_password = '{{ask_auto_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'auto_password') {
	if (!defined($ARGV[1])) {
		$ask_auto_password = (defined($ask_auto_password) && $ask_auto_password ne '{{ask_auto_password}}' && $ask_auto_password ne '')?$ask_auto_password:'';
		if ($ask_auto_password ne '') {
			$question = "Q10a. Do you want to change auto password?(y/N)";
			$answer = "A10a. Skip Set auto password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		if ($isAsk) {
			$ask_auto_password = random_password(20);
			$answer = "A10a. Set auto password OK!";
		}
	}
	else {
		$value = (lc($ARGV[1]) eq 'auto')?random_password(20):$ARGV[1];
		$ask_auto_password = $value;
		$answer = "A10a. Set auto password OK!";
	}
	print ("$answer\n\n");
	if ($ask_auto_password ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_auto_password;
			require($p_config_ans);
			$ask_auto_password=$tmp;
		}
		write_ans();
	}
}

# 10b. Automatically generate random key
#\$ask_random_key = '{{ask_random_key}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'random_key') {
	if (!defined($ARGV[1])) {
		$ask_random_key = (defined($ask_random_key) && $ask_random_key ne '{{random_key}}' && $ask_random_key ne '')?$ask_random_key:'';
		if ($ask_random_key ne '') {
			$question = "Q10b. Do you want to change random key?(y/N)";
			$answer = "A10b. Skip Set random key!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		if ($isAsk) {
			$ask_random_key = random_password(20);
			$answer = "A10b. Set random key OK!";
		}
	}
	else {
		$value = (lc($ARGV[1]) eq 'auto')?random_password(20):$ARGV[1];
		$ask_random_key = $value;
		$answer = "A10b. Set random key OK!";
	}
	print ("$answer\n\n");
	if ($ask_random_key ne '') {
		if (-e $p_config_ans) {
			$tmp=$ask_random_key;
			require($p_config_ans);
			$ask_random_key=$tmp;
		}
		write_ans();
	}
}

#------------------------------
# checkmarx setting(Option)
#------------------------------
if (!defined($ARGV[0])) {
	$question = "Q11. Do you want to change Checkmarx setting(Option)?(y/N)";
	$answer = "A11. Skip Set Checkmarx setting!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk = 1;
}
if ($isAsk) {
	require($Bin.'/generate_env_checkmarx.pl');
}

#------------------------------
# WebInspect setting(Option)
#------------------------------
if (!defined($ARGV[0])) {
	$question = "Q12. Do you want to change WebInspect setting(Option)?(y/N)";
	$answer = "A12. Skip Set WebInspect setting!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk = 1;
}
if ($isAsk) {
	require($Bin.'/generate_env_webinspect.pl');
}


#------------------------------
# 21. Generate env.pl
#------------------------------
$question = "Q21. Do you want to generate env.pl based on the above information?(Y/n)";
if(defined($ARGV[2] && lc($ARGV[2]) eq 'force')) {
	$Y_N = 'y';
}
else {
	$Y_N = prompt_for_input($question);
}
if (lc($Y_N) ne 'n') {
	convert();
}

exit;

# convert env.pl.ans to env.pl
sub convert {
	
	if (-e $p_config) {
		`cat $p_config > $p_config_bak`;
		print("The original env.pl has been backed up as $p_config_bak\n");
	}
	
	$env_template = `cat $p_config_tmpl`;
	$env_template =~ s/{{ask_deploy_mode}}/$ask_deploy_mode/g;
	$env_template =~ s/{{ask_iiidevops_ver}}/$ask_iiidevops_ver/g;
	$env_template =~ s/{{ask_vm1_ip}}/$ask_vm1_ip/g;
	$env_template =~ s/{{ask_vm2_ip}}/$ask_vm2_ip/g;
	$env_template =~ s/{{ask_nfs_ip}}/$ask_nfs_ip/g;
	$env_template =~ s/{{ask_nfs_dir}}/$ask_nfs_dir/g;
	$env_template =~ s/{{ask_rancher_domain_name}}/$ask_rancher_domain_name/g;
	$env_template =~ s/{{ask_gitlab_domain_name}}/$ask_gitlab_domain_name/g;
	$env_template =~ s/{{ask_harbor_domain_name}}/$ask_harbor_domain_name/g;
	$env_template =~ s/{{ask_redmine_domain_name}}/$ask_redmine_domain_name/g;
	$env_template =~ s/{{ask_sonarqube_domain_name}}/$ask_sonarqube_domain_name/g;
	$env_template =~ s/{{ask_k8sctl_domain_name}}/$ask_k8sctl_domain_name/g;
	$env_template =~ s/{{ask_ingress_domain_name}}/$ask_ingress_domain_name/g;
	$env_template =~ s/{{ask_iiidevops_domain_name}}/$ask_iiidevops_domain_name/g;
	$env_template =~ s/{{ask_rancher_domain_name_tls}}/$ask_rancher_domain_name_tls/g;
	$env_template =~ s/{{ask_gitlab_domain_name_tls}}/$ask_gitlab_domain_name_tls/g;
	$env_template =~ s/{{ask_harbor_domain_name_tls}}/$ask_harbor_domain_name_tls/g;
	$env_template =~ s/{{ask_redmine_domain_name_tls}}/$ask_redmine_domain_name_tls/g;
	$env_template =~ s/{{ask_sonarqube_domain_name_tls}}/$ask_sonarqube_domain_name_tls/g;
	$env_template =~ s/{{ask_ingress_domain_name_tls}}/$ask_ingress_domain_name_tls/g;
	$env_template =~ s/{{ask_iiidevops_domain_name_tls}}/$ask_iiidevops_domain_name_tls/g;
	$env_template =~ s/{{ask_gitlab_root_password}}/$ask_gitlab_root_password/g;
	$env_template =~ s/{{ask_gitlab_private_token}}/$ask_gitlab_private_token/g;
	$env_template =~ s/{{ask_rancher_admin_password}}/$ask_rancher_admin_password/g;
	$env_template =~ s/{{ask_redmine_admin_password}}/$ask_redmine_admin_password/g;
	$env_template =~ s/{{ask_redmine_api_key}}/$ask_redmine_api_key/g;
	$env_template =~ s/{{ask_sonarqube_admin_passwd}}/$ask_sonarqube_admin_passwd/g;
	$env_template =~ s/{{ask_sonarqube_admin_token}}/$ask_sonarqube_admin_token/g;
	$env_template =~ s/{{ask_harbor_admin_password}}/$ask_harbor_admin_password/g;
	$env_template =~ s/{{ask_auto_password}}/$ask_auto_password/g;
	$env_template =~ s/{{ask_random_key}}/$ask_random_key/g;
	$env_template =~ s/{{ask_checkmarx_origin}}/$ask_checkmarx_origin/g;
	$env_template =~ s/{{ask_checkmarx_username}}/$ask_checkmarx_username/g;
	$env_template =~ s/{{ask_checkmarx_password}}/$ask_checkmarx_password/g;
	$env_template =~ s/{{ask_checkmarx_secret}}/$ask_checkmarx_secret/g;	
	$env_template =~ s/{{ask_webinspect_base_url}}/$ask_webinspect_base_url/g;
	$env_template =~ s/{{ask_webinspect_type}}/$ask_webinspect_type/g;
	$env_template =~ s/{{ask_webinspect_username}}/$ask_webinspect_username/g;
	$env_template =~ s/{{ask_webinspect_password}}/$ask_webinspect_password/g;
	$env_template =~ s/{{ask_admin_init_login}}/$ask_admin_init_login/g;
	$env_template =~ s/{{ask_admin_init_email}}/$ask_admin_init_email/g;
	$env_template =~ s/{{ask_admin_init_password}}/$ask_admin_init_password/g;
	
	open(FH, '>', $p_config) or die $!;
	print FH $env_template;
	close(FH);
	if (-e $p_config_bak) {
		$cmd_msg = `diff $p_config $p_config_bak`;
	}
	else {
		$cmd_msg = `cat $p_config`;
	}
	print("-----\n$cmd_msg-----\n");
	
	return;
}


sub write_ans {

	$ans_file = $ans_tmpl;
	$ans_file =~ s/{{ask_deploy_mode}}/$ask_deploy_mode/;
	$ans_file =~ s/{{ask_iiidevops_ver}}/$ask_iiidevops_ver/;
	$ans_file =~ s/{{ask_vm1_ip}}/$ask_vm1_ip/;
	$ans_file =~ s/{{ask_vm2_ip}}/$ask_vm2_ip/;
	$ans_file =~ s/{{ask_nfs_ip}}/$ask_nfs_ip/;
	$ans_file =~ s/{{ask_nfs_dir}}/$ask_nfs_dir/;
	$ans_file =~ s/{{ask_rancher_domain_name}}/$ask_rancher_domain_name/g;
	$ans_file =~ s/{{ask_gitlab_domain_name}}/$ask_gitlab_domain_name/g;
	$ans_file =~ s/{{ask_harbor_domain_name}}/$ask_harbor_domain_name/g;
	$ans_file =~ s/{{ask_redmine_domain_name}}/$ask_redmine_domain_name/g;
	$ans_file =~ s/{{ask_sonarqube_domain_name}}/$ask_sonarqube_domain_name/g;
	$ans_file =~ s/{{ask_k8sctl_domain_name}}/$ask_k8sctl_domain_name/g;
	$ans_file =~ s/{{ask_ingress_domain_name}}/$ask_ingress_domain_name/g;
	$ans_file =~ s/{{ask_iiidevops_domain_name}}/$ask_iiidevops_domain_name/g;
	$ans_file =~ s/{{ask_rancher_domain_name_tls}}/$ask_rancher_domain_name_tls/g;
	$ans_file =~ s/{{ask_gitlab_domain_name_tls}}/$ask_gitlab_domain_name_tls/g;
	$ans_file =~ s/{{ask_harbor_domain_name_tls}}/$ask_harbor_domain_name_tls/g;
	$ans_file =~ s/{{ask_redmine_domain_name_tls}}/$ask_redmine_domain_name_tls/g;
	$ans_file =~ s/{{ask_sonarqube_domain_name_tls}}/$ask_sonarqube_domain_name_tls/g;
	$ans_file =~ s/{{ask_ingress_domain_name_tls}}/$ask_ingress_domain_name_tls/g;
	$ans_file =~ s/{{ask_iiidevops_domain_name_tls}}/$ask_iiidevops_domain_name_tls/g;
	$ans_file =~ s/{{ask_gitlab_root_password}}/$ask_gitlab_root_password/;
	$ans_file =~ s/{{ask_gitlab_private_token}}/$ask_gitlab_private_token/;
	$ans_file =~ s/{{ask_rancher_admin_password}}/$ask_rancher_admin_password/;
	$ans_file =~ s/{{ask_redmine_admin_password}}/$ask_redmine_admin_password/;
	$ans_file =~ s/{{ask_redmine_api_key}}/$ask_redmine_api_key/;
	$ans_file =~ s/{{ask_sonarqube_admin_passwd}}/$ask_sonarqube_admin_passwd/;
	$ans_file =~ s/{{ask_sonarqube_admin_token}}/$ask_sonarqube_admin_token/;
	$ans_file =~ s/{{ask_harbor_admin_password}}/$ask_harbor_admin_password/;
	$ans_file =~ s/{{ask_auto_password}}/$ask_auto_password/;
	$ans_file =~ s/{{ask_random_key}}/$ask_random_key/;
	$ans_file =~ s/{{ask_checkmarx_origin}}/$ask_checkmarx_origin/;
	$ans_file =~ s/{{ask_checkmarx_username}}/$ask_checkmarx_username/;
	$ans_file =~ s/{{ask_checkmarx_password}}/$ask_checkmarx_password/;
	$ans_file =~ s/{{ask_checkmarx_secret}}/$ask_checkmarx_secret/;
	$ans_file =~ s/{{ask_webinspect_base_url}}/$ask_webinspect_base_url/;
	$ans_file =~ s/{{ask_webinspect_type}}/$ask_webinspect_type/;
	$ans_file =~ s/{{ask_webinspect_username}}/$ask_webinspect_username/;
	$ans_file =~ s/{{ask_webinspect_password}}/$ask_webinspect_password/;
	$ans_file =~ s/{{ask_admin_init_login}}/$ask_admin_init_login/;
	$ans_file =~ s/{{ask_admin_init_email}}/$ask_admin_init_email/;
	$ans_file =~ s/{{ask_admin_init_password}}/$ask_admin_init_password/;
	
	open(FH, '>', $p_config_ans) or die $!;
	print FH $ans_file;
	close(FH);
	
	return;	
}


# Ref - http://www.tizag.com/perlT/perluserinput.php
sub prompt_for_input {
	my ($p_question) = @_;
    print "$p_question";
	my $answer = <STDIN>;
    $answer =~ s/\R\z//;

    return $answer;
}

# Ref - https://stackoverflow.com/questions/39801195/how-can-perl-prompt-for-a-password-without-showing-it-in-the-terminal
sub prompt_for_password {
	my ($p_question) = @_;
	# Check password rule
	my $regex = qr/(?=.*\d)(?=.*[a-z])(?=.*[A-Z])^[\w!@#$%^&*()+|{}\[\]`~\-\'\";:\/?.\\>,<]{8,20}$/mp;	

	require Term::ReadKey;
	
	my $password = '';
	while(!($password =~ /$regex/g) && lc($password) ne 'same') {
		# Tell the terminal not to show the typed chars
		Term::ReadKey::ReadMode('noecho');
		print "$p_question";
		$password = Term::ReadKey::ReadLine(0);
		# Rest the terminal to what it was previously doing
		Term::ReadKey::ReadMode('restore');
		print "\n";

		# get rid of that pesky line ending (and works on Windows)
		$password =~ s/\R\z//;
	}

    return $password;
}

# Ref - https://utdream.org/quick-random-password-generator-for-perl/
sub random_password {
	my ($password_len) = @_;
	my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9); #('a'..'z', 'A'..'Z', 0..9,'!','_','-');
	my @numeric = (0..9);
	my $randpassword = '';
	my $password_len_max = ($password_len>0)?$password_len:16;
	

	until ( length($randpassword) > $password_len_max ) {
        $randpassword = $randpassword . join '', map $alphanumeric[rand @alphanumeric], 0..(rand @numeric);
	}
	
	return($randpassword);
}