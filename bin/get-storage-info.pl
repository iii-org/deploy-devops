#!/usr/bin/perl
# Get Storage Info.
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
$g_mode = defined($ARGV[0])?lc($ARGV[0]):'display'; # log or display (Default)
$g_now = `TZ='Asia/Taipei' date +"%Y-%m-%d %H:%M:%S"`;
$g_now =~ s/\n|\r//g;

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'root') {
	print("You must use the 'root' account to run the script!\n");
	exit;
}

# check log file
if ($g_mode eq 'log') {
	$logfile = $nfs_dir.'/deploy-config/storage_info.log';
	$header = "datetime,total,used,available,use%,redmine_file,redmine_db,gitlab,harbor_pvc\n";
	if (!-e $logfile) {
		open(FH, '>', $logfile) or die $!;
		print FH $header;
		close(FH);
	}
}

# Total Storage Info
$cmd = "df $nfs_dir | tail -1";
$cmd_msg = `$cmd 2>&1`;
$cmd_msg =~ s/( )+/ /g;
($t1, $total, $used, $available, $use_percent) = split(/ /, $cmd_msg);

# Redmine-file
$cmd = "sudo du $nfs_dir/redmine-files/ | tail -1";
$cmd_msg = `$cmd 2>&1`;
($redmine_file) = split(/\t/, $cmd_msg);

# Redmine-db
$cmd = "sudo du $nfs_dir/redmine-postgresql/ | tail -1";
$cmd_msg = `$cmd 2>&1`;
($redmine_db) = split(/\t/, $cmd_msg);

# Gitlab
$cmd = "sudo du $nfs_dir/gitlab/ | tail -1";
$cmd_msg = `$cmd 2>&1`;
($gitlab) = split(/\t/, $cmd_msg);

# Harbor-pvc
$cmd = "sudo du $nfs_dir/pvc/ | tail -1";
$cmd_msg = `$cmd 2>&1`;
($harbor_pvc) = split(/\t/, $cmd_msg);

$line = "$g_now,$total,$used,$available,$use_percent,$redmine_file,$redmine_db,$gitlab,$harbor_pvc\n";
if ($g_mode eq 'log') {
	open(FH, '>>', $logfile) or die $!;
	print FH $line;
	close(FH);
}
else {
	print($line);
}

exit;
