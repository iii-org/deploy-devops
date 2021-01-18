#!/usr/bin/perl
# Install GitLab service script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$gitlab_domain_name = ($gitlab_domain_name eq '')?"gitlab.iiidevops.$gitlab_ip.xip.io":$gitlab_domain_name;
log_print("Install GitLab URL: http://$gitlab_domain_name\n");
# Check GitLab is working
$cmd_msg = `nc -z -v $gitlab_ip 80 2>&1`;
$isWorking = index($cmd_msg, 'succeeded!')<0?0:1;
if ($isWorking) {
	log_print("GitLab is running, I skip the installation!\n\n");
	exit;
}

$cmd =
"sudo docker run --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://$gitlab_domain_name';gitlab_rails['initial_root_password'] = '$gitlab_root_passwd';gitlab_rails['gitlab_default_projects_features_builds'] = 'false'\"  --detach --publish 443:443 --publish 80:80 --publish 10022:22 --name gitlab --restart always --volume $data_dir/gitlab/config:/etc/gitlab --volume $data_dir/gitlab/logs:/var/log/gitlab --volume $data_dir/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:12.10.6-ce.0";
log_print("-----\n$cmd\n\n");

$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check GitLab service is working
$cmd = "curl -q -I http://$gitlab_domain_name/users/sign_in";
#HTTP/1.1 200 OK
$chk_key = '200 OK';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("-----\n$cmd_msg-----\n");
if ($isChk) {
	log_print("Failed to deploy GitLab!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed GitLab!\n");
exit;


sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}