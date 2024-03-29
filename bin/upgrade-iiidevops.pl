#!/usr/bin/perl
# Upgrade iiidevops using bin/patch script
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
$ins_repo = (!defined($ARGV[0]))?'master':$ARGV[0];
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}
$update_prj =`cd ~; wget -O update-perl.pl https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/update-perl.pl; perl ./update-perl.pl;`;

# chdir "~/deploy-devops/bin/patch";
$tmpl_list = `ls ~/deploy-devops/bin/patch/*.pl`;
$patch_num = 0;
$cmd = '';
foreach $tmpl_name (split(".pl\n", $tmpl_list)) {
	if($tmpl_name ne 'p000') {
		$cmd .= "perl $tmpl_name.pl;"		
	}
}
system($cmd);

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}
