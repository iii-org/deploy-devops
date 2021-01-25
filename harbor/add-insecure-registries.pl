#!/usr/bin/perl
# add insecure-registries script
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


#sudo vi /etc/docker/daemon.json
#{
#    "insecure-registries":["10.20.0.71:32443"]
#}
$docker_daemon_json = "/etc/docker/daemon.json";
if (-e $docker_daemon_json) {
	$cmd_msg = `cat $docker_daemon_json`;
	if (index($cmd_msg, $harbor_ip.':32443')>0) {
		log_print("Harbor IP [$harbor_ip] already exists in daemon.json!\n");
		exit;
	}
	if ($cmd_msg ne '') {
		# Please manually append "insecure-registries":["10.20.0.71:32443"]
		log_print("Please manually append $harbor_ip:32443 into 'insecure-registries' in $docker_daemon_json\nExp. \"insecure-registries\":[\"10.20.0.11:32443\", \"$$harbor_ip:32443\"]\nThen restart socker.service\n\n");
		exit;
	}
}

# New file
$new_daemon_json =<<END;
{
    "insecure-registries":["$harbor_ip:32443"]
}

END

log_print("-----\n$new_daemon_json\n-----\n");
open(FH, '>', $docker_daemon_json) or die $!;
print FH $new_daemon_json;
close(FH);

#sudo systemctl restart docker.service
$cmd = "sudo systemctl restart docker.service";
log_print("Restart docker service..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");
log_print("\nSuccessfully add $harbor_ip into insecure-registries!\n");
exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}