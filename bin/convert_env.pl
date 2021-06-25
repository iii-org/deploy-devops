#!/usr/bin/perl
# Convert env.conf to env.pl.ans to env.pl script
#
use FindBin qw($Bin);

$p_conf = "$Bin/../env.conf";
$p_config_ans = "$Bin/../env.pl.ans";
$p_config_ans_bak = $p_config_ans.".bak";

$nfs_dir = defined($nfs_dir)?$nfs_dir:'/iiidevopsNFS';
if (-e "$nfs_dir/deploy-config/env.pl.ans") {
	#$cmd_msg = `rm -f $p_config_ans; ln -s $nfs_dir/deploy-config/env.pl.ans $p_config_ans`; 
	print("The conf ans file [env.pl.ans] exist!\n");
	exit;
}
if (-e "$nfs_dir/deploy-config/env.conf") {
	$cmd_msg = `rm -f $p_conf; ln -s $nfs_dir/deploy-config/env.conf $p_conf`; 
}

if (!-e $p_conf) {
	print("The conf file [$p_conf] does not exist!\n");
	exit;
}

$p_config_ans_tmpl = $p_config_ans.".tmpl";
if (!-e $p_config_ans_tmpl) {
	print("The template file [$p_config_ans_tmpl] does not exist!\n");
	exit;
}
$ans_tmpl = `cat $p_config_ans_tmpl`;

# Parsing env.conf
$hash_conf = {};
parsing_conf();

# Backup env.pl.ans
if (-e $p_config_ans) {
	`cat $p_config_ans > $p_config_ans_bak`;
	print("The original env.pl.ans has been backed up as $p_config_ans_bak\n");
}

# Replace env.pl.ans template
	$env_template = $ans_tmpl;
	$env_template =~ s/{{ask_deploy_mode}}/$hash_conf{'DEPLOY_MODE'}/g;
	$env_template =~ s/{{ask_iiidevops_ver}}/$hash_conf{'VERSION'}/g;
	$env_template =~ s/{{ask_vm1_ip}}/$hash_conf{'VM1_IP'}/g;
	$env_template =~ s/{{ask_vm2_ip}}/$hash_conf{'VM2_IP'}/g;
	$env_template =~ s/{{ask_nfs_ip}}/$hash_conf{'NFS_IP'}/g;
	$env_template =~ s/{{ask_nfs_dir}}/$hash_conf{'NFS_DIR'}/g;
	$env_template =~ s/{{ask_rancher_domain_name}}/$hash_conf{'RANCHER_DOMAIN'}/g;
	$env_template =~ s/{{ask_gitlab_domain_name}}/$hash_conf{'GITLAB_DOMAIN'}/g;
	$env_template =~ s/{{ask_harbor_domain_name}}/$hash_conf{'HARBOR_DOMAIN'}/g;
	$env_template =~ s/{{ask_redmine_domain_name}}/$hash_conf{'REMINE_DOMAIN'}/g;
	$env_template =~ s/{{ask_sonarqube_domain_name}}/$hash_conf{'SONARQUBE_DOMAIN'}/g;
	$env_template =~ s/{{ask_k8sctl_domain_name}}/$hash_conf{'K8SCTL_DOMAIN'}/g;
	$env_template =~ s/{{ask_ingress_domain_name}}/$hash_conf{'INGRESS_DOMAIN'}/g;
	$env_template =~ s/{{ask_iiidevops_domain_name}}/$hash_conf{'IIIDEVOPS_DOMAIN'}/g;
	$env_template =~ s/{{ask_gitlab_root_password}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_gitlab_private_token}}/$hash_conf{'GITLAB_PRIVATE_TOKEN'}/g;
	$env_template =~ s/{{ask_rancher_admin_password}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_redmine_admin_password}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_redmine_api_key}}/$hash_conf{'REDMINE_API_KEY'}/g;
	$env_template =~ s/{{ask_sonarqube_admin_passwd}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_sonarqube_admin_token}}/$hash_conf{'SONARQUBE_ADMIN_TOKEN'}/g;
	$env_template =~ s/{{ask_harbor_admin_password}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_admin_init_login}}/$hash_conf{'ADMIN_INIT_LOGIN'}/g;
	$env_template =~ s/{{ask_admin_init_email}}/$hash_conf{'ADMIN_INIT_EMAIL'}/g;
	$env_template =~ s/{{ask_admin_init_password}}/$hash_conf{'GITLAB_ROOT_PWD'}/g;
	$env_template =~ s/{{ask_rancher_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_gitlab_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_redmine_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_harbor_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_sonarqube_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_ingress_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_iiidevops_domain_name_tls}}//g ;
	$env_template =~ s/{{ask_checkmarx_origin}}//g;
	$env_template =~ s/{{ask_checkmarx_username}}//g;
	$env_template =~ s/{{ask_checkmarx_password}}//g;
	$env_template =~ s/{{ask_checkmarx_secret}}//g;	
	$env_template =~ s/{{ask_webinspect_base_url}}//g;
	$env_template =~ s/{{ask_webinspect_type}}//g ;
	$env_template =~ s/{{ask_webinspect_username}}//g ;
	$env_template =~ s/{{ask_webinspect_password}}//g ;
	$env_template =~ s/{{ask_auto_password}}/$hash_conf{'AUTO_PWD'}/g;
	$env_template =~ s/{{ask_random_key}}/$hash_conf{'RANDOM_KEY'}/g;
	
	open(FH, '>', $p_config_ans) or die $!;
	print FH $env_template;
	close(FH);
	if (-e $p_config_ans_bak) {
		$cmd_msg = `diff $p_config_ans $p_config_ans_bak`;
	}
	else {
		$cmd_msg = `cat $p_config_ans`;
	}
	print("-----\n$cmd_msg-----\n");
	
	# convert env.pl.ans to env.pl
	$cmd = "$Bin/generate_env.pl convert";
	system($cmd);

	# redmine_api_key
	if (lc($hash_conf{'REDMINE_API_KEY'}) eq 'skip') {
		$cmd = "$Bin/generate_env.pl redmine_api_key auto force";
		system($cmd);
	}
	# auto_password
	if (lc($hash_conf{'AUTO_PWD'}) eq 'skip') {
		$cmd = "$Bin/generate_env.pl auto_password auto force";
		system($cmd);
	}
	# random_key
	if (lc($hash_conf{'RANDOM_KEY'}) eq 'skip') {
		$cmd = "$Bin/generate_env.pl random_key auto force";
		system($cmd);
	}

exit;

# Parsing env.conf to $hash_conf{key}=value
sub parsing_conf {
	my($msg, $line, $key, $value);
	
	$msg = `cat $p_conf`;
	$msg =~ s/\r//g;
	foreach $line (split(/\n/, $msg)) {
		if (substr($line,0,1) eq '#' || $line eq '') {
			next;
		}
		($key, $value) = split('=', $line);
		if (length($key)==0 || length($value)==0) {
			print("ERR:[$line]\n");
			next;
		}
		$value =~ s/\"//g;
		$hash_conf{$key}=$value;
	}
	
	return;
}
