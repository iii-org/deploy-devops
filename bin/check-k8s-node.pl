#!/usr/bin/perl
# Check NFS Client for remote Kubernetes worker node script
#
use FindBin qw($Bin);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
if (!defined($ARGV[0])) {
	print("Usage: $prgname user\@remote_ip\n");
	exit;
}

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	log_print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$harbor_cert = "$data_dir/harbor/certs/$harbor_ip.crt";
if (!-e $harbor_cert) {
	log_print("The Harbor server cert file [$harbor_cert] does not exist!\n");
	exit;
}

# copy habor server cert to remote k8s node
$cmd = "scp $harbor_cert $ARGV[0]:~";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n\n");
log_print("\n");

# run and get remote k8s node info
$cmd = "ssh $ARGV[0] \"showmount -e $nfs_ip; sudo -S cp ~/$harbor_ip.crt /usr/local/share/ca-certificates/; sudo update-ca-certificates; sudo systemctl restart docker.service; ls /etc/ssl/certs | awk /$harbor_ip/\"";
log_print("-----\n$cmd\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n\n");

# Check remote k8s node info
$nfs_check = (index($cmd_msg, "$nfs_dir *")<0)?"ERROR!":"OK!";
$harbor_cert_check = (index($cmd_msg, "$harbor_ip.pem")<0)?"ERROR!":"OK!";
log_print("-----Validation results-----\n");
log_print("NFS Client	: $nfs_check\n");
log_print("Harbor Cert	: $harbor_cert_check\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}