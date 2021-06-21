#!/usr/bin/perl
# Install nfs service script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
$|=1; # force flush output

if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

log_print("Install NFS : $nfs_ip - $nfs_dir\n");
# Check NFS is working
$cmd_msg = `showmount -e $nfs_ip 2>&1`;
$isWorking = index($cmd_msg, $nfs_dir)<0?0:1;
if ($isWorking) {
	log_print("NFS is running, I skip the installation!\n\n");
	exit;
}

#$cmd = "sudo apt install nfs-kernel-server -y";
#log_print("Install NFS service Package..\n");
#$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n");

$cmd_msg = `sudo cat /etc/exports`;
if (index($cmd_msg, $nfs_dir)<0) {
	$cmd = "echo '$nfs_dir *(no_root_squash,rw,sync,no_subtree_check)' |sudo tee -a /etc/exports";
	log_print("-----\n$cmd\n");
	$cmd_msg = `$cmd`;
	log_print("-----\n$cmd_msg\n-----\n");
}

$cmd = "sudo systemctl restart nfs-kernel-server";
log_print("Setting & Restart NFS Service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

# Check NFS service is working
$cmd = "showmount -e $nfs_ip";
#/iiidevopsNFS *
$chk_key = $nfs_dir;
$isChk=1;
$count=0;
$wait_sec=60;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("-----\n$cmd_msg-----\n");
if ($isChk) {
	log_print("NFS configuration failed!\n");
	exit;
}
log_print("NFS configuration OK!\n");

exit;