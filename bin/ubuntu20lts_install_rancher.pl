#!/usr/bin/perl
# Install nfs service script
#
use FindBin qw($Bin);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$home_dir = "/data";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);


$cmd = "sudo mkdir $home_dir/rancher; sudo chmod 755 $home_dir/rancher &";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

$cmd = "sudo docker run -d --restart=unless-stopped -p 6080:80 -p 6443:443 -v $home_dir/rancher:/var/lib/rancher rancher/rancher:v2.4.5 &";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}