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

log_print("Install GitLab URL: http://$gitlab_ip\n");
$cmd =
"sudo docker run --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://$gitlab_ip';\"  --detach --publish 443:443 --publish 80:80 --publish 10022:22 --name gitlab --restart always --volume $data_dir/gitlab/config:/etc/gitlab --volume $data_dir/gitlab/logs:/var/log/gitlab --volume $data_dir/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:12.10.6-ce.0";
log_print("-----\n$cmd\n\n");

$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check GitLab service is working
$cmd = "nc -z -v $gitlab_ip 80";
# Connection to 10.20.0.71 80 port [tcp/*] succeeded!
$chk_key = 'succeeded!';
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