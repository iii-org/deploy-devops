#!/usr/bin/perl
# add insecure-registries script
#
# Usage: sudo add-insecure-registries.pl <harbor_ip> <harbor_domain_name>
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0])) {
	print("Usage:	sudo $prgname <harbor_ip> <harbor_domain_name>\n");
	exit;
}
$logfile = "$Bin/$prgname.log";

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

$harbor_ip = $ARGV[0];
$harbor_domain_name = (defined($ARGV[1]))?$ARGV[1]:'';

#sudo vi /etc/docker/daemon.json
#{
#    "insecure-registries":["10.20.0.71:32443", "harbor.iiidevops.org"]
#}
$docker_daemon_json = "/etc/docker/daemon.json";
if (-e $docker_daemon_json) {
	$cmd_msg = `cat $docker_daemon_json`;
	if (index($cmd_msg, $harbor_ip.':32443')>0) {
		log_print("Harbor IP [$harbor_ip] already exists in daemon.json!\nThe Docker of the node should be able to trust $harbor_ip\n");
		exit;
	}
	if ($cmd_msg ne '') {
		# Please manually append "insecure-registries":["10.20.0.71:32443"]
		log_print("Please manually append $harbor_ip:32443 into 'insecure-registries' in $docker_daemon_json\nExp. \"insecure-registries\":[\"10.20.0.11:32443\", \"$harbor_ip:32443\"]\nThen restart socker.service\n\n");
		exit;
	}
}

# New file
$insecure_registries = "\"$harbor_ip:32443\"";
if ($harbor_domain_name ne '') {
	$insecure_registries .= ", \"$harbor_domain_name\"";
}
$new_daemon_json =<<END;
{
    "insecure-registries":[$insecure_registries]
}

END

log_print("-----\n$new_daemon_json\n-----\n");
open(FH, '>', $docker_daemon_json) or die $!;
print FH $new_daemon_json;
close(FH);

#sudo systemctl reload docker.service
$cmd = "sudo systemctl reload docker.service";
log_print("Reload docker service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");
log_print("\nSuccessfully add $harbor_ip into insecure-registries!\nThe Docker of the node should be able to trust $harbor_ip\n");
exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}