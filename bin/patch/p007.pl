#!/usr/bin/perl
# 2022/12/26
# Add crontab job for delete cronjob and restart api pod
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

sub install_crontab {
    my $time = "0 4 * * SAT";
    my $job = "$time $Bin/../cleanup-cronjob-and-restart-api.pl";

    # Check crontab if job is existed
    my $cmd = `crontab -l | grep -F '$job'`;

    if ($cmd) {
        print("The crontab job is already exist!\n");
        return;
    }

    my $cmd = `(crontab -l 2>/dev/null; echo "$job") | crontab -`;
    print("The crontab job is installed!\n");
    print("Installed job: " . `crontab -l | grep -F '$job'`);
}

install_crontab();
