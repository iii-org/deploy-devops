#!/usr/bin/perl
# Remove develop env K8s user namespace deployments
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
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/common_lib.pl");

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
    print("username:$cmd_msg\n")
	print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$cronid = (!defined($ARGV[0]))?'no_cronid':$ARGV[0];
$active = (!defined($ARGV[1]))?'no_active':$ARGV[1];
$runtime = (!defined($ARGV[2]))?'no_time':$ARGV[2];

if ($cronid eq 'no_cronid' || $active eq 'no_active') {
	print("Error: $prgname Incomplete parameters [cronid:$cronid active:$active runtime:$runtime] \n");
	exit;
}

if ($cronid eq 'sync_tmpl') {
    if ($active eq 'on') {
        $argc1 = (!defined($ARGV[3]))?'':$ARGV[3];
	    print("$prgname $active $runtime $argc1\n");
        system(`echo "$runtime /home/rkeuser/deploy-devops/bin/sync-prj-templ.pl $argc1 >> /tmp/sync-prj-templ.log 2>&1" > /home/rkeuser/cron.txt;crontab cron.txt`);
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n")
        exit;
    }
    elsif ($active eq 'off') {
        print("$prgname $active \n");
    }
    else{
        print("Error: $prgname active parameters error! \n");
	    exit; 
    }
}