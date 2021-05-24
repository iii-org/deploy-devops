#!/usr/bin/perl
# update Kubernetes cluster script (Run @first_node)
#
# Check $nfs_dir/deploy-config/*.ready
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
$pidfile = "$Bin/$prgname.pid";
require("$Bin/../lib/common_lib.pl");

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check runtime user
$cmd = "whoami";
$cmd_msg = `$cmd 2>&1`;
$chk_key = 'rkeuser';
if (index($cmd_msg, $chk_key)<0) {
	log_print("Must use 'rkeuser' user to join K8s cluster!\n");
	exit;
}

# Check if another process is running
if (-e $pidfile) {
	$t_pid = `cat $pidfile`;
	$t_pid =~ s/\n|\r//g;
	$exists = kill 0, $t_pid;
	if ($exists) {
		log_print("Another process [$t_pid] is running!\n");
		exit;
	}
}

# Gen pid file
$my_pid = $$;
`echo $my_pid > $pidfile`;

$to_chk=1;
while ($to_chk) {
	$to_update=0;
	while ($to_chk) {
		$to_chk = check_ready_ips();
		$to_update = ($to_update==0 && $to_chk==0)?0:1;
		if ($to_chk>0) {
			sleep(10);
		}
	}
	if ($to_update>0) {
		log_print("\n----------------------------------------\n");
		log_print(`TZ='Asia/Taipei' date`);
		# update K8s cluster
		update_k8s_cluster();
		sleep(10);
	}
}
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
log_print("Complete the update of K8s cluster!\n");
exit;


# Check *.ready
sub check_ready_ips {
	my ($cmd, $cmd_msg, $chk_key, $ip_ready, $idx);
	
	$cmd = "ls -m $nfs_dir/deploy-config/*.ready";
	$cmd_msg = `$cmd 2>&1`;
	$chk_key = ': No such file or directory';
	if (index($cmd_msg, $chk_key)>0) {
		log_print("No ready files!\n");
		return(0);
	}

	$cmd_msg =~ s/\n|\r|.ready//g;
	$cmd_msg =~ s/$nfs_dir|deploy-config|\///g;
	log_print("[$cmd_msg]\n");
	$idx = 0;
	foreach $ip_ready (split(',', $cmd_msg)) {
		$idx++;
		$cmd_msg = `$Bin/../kubernetes/update-k8s-setting.pl Add $ip_ready`;
		system("rm $nfs_dir/deploy-config/$ip_ready.ready");
		if (index($cmd_msg, $ip_ready)>=0) {
			log_print("Add [$ip_ready] to cluster Failed!\n$cmd_msg\n");
		}
		else {
			log_print("Add [$ip_ready] to cluster OK!\n");
		}
	}

	return($idx);
}

# Update K8s cluster
sub update_k8s_cluster {
	my ($cmd, $cmd_msg);
	
	$cmd = "sudo -u rkeuser rke up --update-only --config $nfs_dir/deploy-config/cluster.yml";
	$cmd_msg = `$cmd 2>&1`;
	log_print("[$cmd]\n$cmd_msg\n");
	
	return;
}