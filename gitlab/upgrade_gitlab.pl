#!/usr/bin/perl
# Upgrade GitLab service script
# from 12.10.14 to 13.12.15
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($gitlab_ip eq '') {
	print("The gitlab_ip in [$p_config] is ''!\n\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check GitLab service is working
if (!get_service_status('gitlab')) {
	log_print("GitLab is not running, I aborted the upgrade!\n\n");
	exit;
}

# 12.10.6, 12.10.14, 13.0.14, 13.1.11, 13.12.15
@arr_allow_ver = split(/, /, "12.10.6, 12.10.14, 13.0.14, 13.1.11, 13.12.15");

# Check GitLab version
$v_cmd_msg = call_gitlab_api('GET', 'version');
if ($v_cmd_msg eq 'GitLab is not responding') {
	log_print("GitLab is not working well, I aborted the upgrade!\n\n");
	exit;
}
	
$v_hash_msg = decode_json($v_cmd_msg);
$v_now_gitlab_ver = $v_hash_msg->{'version'};

$t_found=0;
foreach $t_ver (@arr_allow_ver) {
	if ($t_found==0) {
		if ($t_ver eq $v_now_gitlab_ver) {
			$t_found=1;
			next;
		}
		next;
	}
	log_print("Upgrade GitLab to version $t_ver ..");
	# call upgrage process
	$v_gitlab_ver = call_upgrade_gitlab($t_ver);
	if ($v_gitlab_ver ne $t_ver) {
		# upgrade fail
		log_print("Failed! [$v_gitlab_ver]\n\n");
		exit;
	}
	log_print("OK!\n");
}

if ($t_found==0) {
	log_print("Your GitLab version $v_now_gitlab_ver is not the version expected to be upgraded!\n\n");
	exit;
}

if ($v_gitlab_ver eq '') {
	log_print("Your GitLab version $v_now_gitlab_ver is already an upgraded version!\n\n");
	exit;
}

log_print("Your GitLab version $v_now_gitlab_ver has been successfully upgraded to $v_gitlab_ver!\n\n");
exit;

# Upgrade Gitlab version
sub call_upgrade_gitlab {
	my ($p_version) = @_;
	my ($v_gitlab_domain_name, $v_gitlab_url, $v_yaml_file, $v_yaml_path, $v_tmpl_file, $v_template, $v_host_aliases);
	my ($v_isChk, $v_items, $v_line, $l_name, $l_ready, $l_status, $l_restarts, $l_age, $v_count, $v_wait_sec, $v_cmd_msg, $v_hash_msg, $v_gitlab_ver);

	# Modify gitlab/gitlab-deployment.yml.tmpl
	$v_gitlab_domain_name = get_domain_name('gitlab');
	$v_gitlab_url = ($gitlab_domain_name_tls ne '')?'https://'.$v_gitlab_domain_name:'http://'.$v_gitlab_domain_name;
	$v_yaml_path = "$Bin/../gitlab/";
	$v_yaml_file = $v_yaml_path.'gitlab-deployment.yml';
	$v_tmpl_file = $v_yaml_file.'.tmpl';
	if (!-e $v_tmpl_file) {
		return("The template file [$v_tmpl_file] does not exist!");
	}
	
	$v_template = `cat $v_tmpl_file`;
	$v_template =~ s/{{gitlab_ver}}/$p_version/g;
	$v_template =~ s/{{gitlab_url}}/$v_gitlab_url/g;
	$v_template =~ s/{{gitlab_root_passwd}}/$gitlab_root_passwd/g;
	$v_template =~ s/{{nfs_ip}}/$nfs_ip/g;
	$v_template =~ s/{{nfs_dir}}/$nfs_dir/g;
	if ($deploy_mode eq 'DNS') {
		$v_host_aliases =<<END;
hostAliases:
      - hostnames:
        - "$gitlab_domain_name"
        ip: 127.0.0.1
END
		$v_template =~ s/{{hostAliases}}/$v_host_aliases/g;
	}
	else {
		$v_template =~ s/{{hostAliases}}//g;
	}
	open(FH, '>', $v_yaml_file) or die $!;
	print FH $v_template;
	close(FH);
	system(`kubectl apply -f $v_yaml_file`);
	
	# check deploy status
	$v_isChk=1;
	while($v_isChk) {
		$v_isChk = 0;
		$v_items = 0;
		foreach $v_line (split(/\n/, `kubectl get pod | grep gitlab- | grep -v sync-gitlab-`)) {
			$v_line =~ s/( )+/ /g;
			($l_name, $l_ready, $l_status, $l_restarts, $l_age) = split(/ /, $v_line);
			if ($l_name eq 'NAME') {next;}
			if ($l_status ne 'Running') {
				log_print('.');
				$v_isChk = 3;
			}
			$v_items ++;
		}
		# Check that there is only 1 running Pod
		if ($v_items>1) {
			log_print('+');
			$v_isChk = 3;
		}
		sleep($v_isChk);
	}

	# Check GitLab service is working
	$v_isChk=1;
	$v_count=0;
	$v_wait_sec=1200;
	while($v_isChk && $v_count<$v_wait_sec) {
		log_print('-');
		$v_isChk = (!get_service_status('gitlab'))?3:0;
		$v_count = $v_count + $v_isChk;
		sleep($v_isChk);
	}
	if ($v_isChk) {
		return("Failed to deploy GitLab!");
	}

	# Get Gitlab version
	$v_isChk=1;
	$v_count=0;
	$v_wait_sec=1200;
	while($v_isChk && $v_count<$v_wait_sec) {
		log_print('.');
		$v_cmd_msg = call_gitlab_api('GET', 'version');
		$v_isChk = ($v_cmd_msg eq 'GitLab is not responding')?3:0;
		$v_count = $v_count + $v_isChk;
		sleep($v_isChk);
	}
	if ($v_isChk) {
		return("Failed to deploy GitLab! [$v_cmd_msg]");
	}
	
	$v_hash_msg = decode_json($v_cmd_msg);
	$v_gitlab_ver = $v_hash_msg->{'version'};
	
	return($v_gitlab_ver);
}