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
    print("username:$cmd_msg\n");
	print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$cronid = (!defined($ARGV[0]))?'no_cronid':$ARGV[0];
$active = (!defined($ARGV[1]))?'no_active':$ARGV[1];
$runtime = (!defined($ARGV[2]))?'no_time':$ARGV[2];

if ($cronid eq 'no_cronid' || $active eq 'no_active') {
	print("Error: $prgname Incomplete parameters [CronID:$cronid Active:$active Runtime:$runtime] \n");
	exit;
}

if ($cronid eq 'sync_tmpl') {
    if ($active eq 'on') {
        $argc1 = (!defined($ARGV[3]))?'':$ARGV[3];
	    print("$prgname $active $runtime $argc1\n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/sync-prj-templ.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/sync-prj-templ.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        system(`echo "$runtime /home/rkeuser/deploy-devops/bin/sync-prj-templ.pl $argc1 >> /tmp/sync-prj-templ.log 2>&1" >> /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    elsif ($active eq 'off') {
        print("$prgname $active \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/sync-prj-templ.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/sync-prj-templ.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    else {
        print("Error: $prgname Active parameters error! \n");
	    exit; 
    }
}
elsif ($cronid eq 'sync_chart') {
    if ($active eq 'on') {
	    print("$prgname $active $runtime \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/sync_chart_index.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/sync_chart_index.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        system(`echo "$runtime /home/rkeuser/deploy-devops/bin/sync_chart_index.pl gitlab_update >> /tmp/sync-chart-index.log 2>&1" >> /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    elsif ($active eq 'off') {
        print("$prgname $active \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/sync_chart_index.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/sync_chart_index.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    else {
        print("Error: $prgname Active parameters error! \n");
	    exit; 
    }
}
elsif ($cronid eq 'redeploy_core') {
    if ($active eq 'on') {
        $argc1 = (!defined($ARGV[3]))?'/home/rkeuser/.kube/config':$ARGV[3];
	    print("$prgname $active $runtime \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/redeploy_core.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/redeploy_core.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        system(`echo "$runtime /home/rkeuser/deploy-devops/bin/redeploy_core.pl $argc1 >> /tmp/iiidevops_update.log 2>&1" >> /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    elsif ($active eq 'off') {
        print("$prgname $active \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/redeploy_core.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/redeploy_core.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    else {
        print("Error: $prgname Active parameters error! \n");
	    exit; 
    }
}
elsif ($cronid eq 'rm_dev_deployment') {
    if ($active eq 'on') {
        print("$prgname $active $runtime \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/rm-dev-deployment.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/rm-dev-deployment.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        system(`echo "$runtime /home/rkeuser/deploy-devops/bin/rm-dev-deployment.pl >> /tmp/iiidevops_update.log 2>&1" >> /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    elsif ($active eq 'off') {
        print("$prgname $active \n");
        if (index(`cat /home/rkeuser/cron.txt`, '/home/rkeuser/deploy-devops/bin/rm-dev-deployment.pl')>=0) {
            system(`sed -i '/\\/home\\/rkeuser\\/deploy-devops\\/bin\\/rm-dev-deployment.pl/d' /home/rkeuser/cron.txt; crontab /home/rkeuser/cron.txt`);
        }
        $cron_msg = `crontab -l`;
        print("show crontab :\n$cron_msg\n");
        exit;
    }
    else {
        print("Error: $prgname Active parameters error! \n");
	    exit; 
    }
}
else {
    print("Error: $prgname CronID not found")
}