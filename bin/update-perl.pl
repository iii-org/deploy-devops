#!/usr/bin/perl
# Update iiidevops perl script
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
$ins_repo = (!defined($ARGV[0]))?'master':$ARGV[0];

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

# check running path
$home_path = '/home/rkeuser';
if ($Bin ne $home_path) {
	log_print("You must run the installation script in [$home_path]!\n");
	exit;
}

# Install iiidevops Deploy Scripts
$cmd = <<END;
cd $home_path;
wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip
unzip -o $ins_repo.zip;
rm -rf deploy-devops;
mv deploy-devops-$ins_repo deploy-devops;
find $home_path/deploy-devops -type f -name \"*.pl\" -exec chmod a+x {} \\;
END
print("Install iiidevops Deploy Scripts..\n");
system($cmd);

exit;
