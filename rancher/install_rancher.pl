#!/usr/bin/perl
# Install rancher service script
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

log_print("Install Rancher URL: https://$rancher_ip:3443\n");
# Check Rancher is working
$cmd_msg = `nc -z -v $rancher_ip 3443 2>&1`;
$isWorking = index($cmd_msg, 'succeeded!')<0?0:1;
if ($isWorking) {
	log_print("Rancher is running, I skip the installation!\n\n");
	exit;
}

$cmd = "sudo mkdir $data_dir/rancher; sudo chmod 755 $data_dir/rancher &";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd = "sudo docker run -d --restart=unless-stopped -p 3080:80 -p 3443:443 -v $data_dir/rancher:/var/lib/rancher rancher/rancher:v2.4.5 &";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check Rancher service is working
$cmd = "nc -z -v $rancher_ip 3443";
# Connection to 10.20.0.71 3443 port [tcp/*] succeeded!
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
	log_print("Failed to deploy Rancher!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Rancher!\n");
exit;


sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}