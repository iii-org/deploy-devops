#!/usr/bin/perl
# Update iiidevops perl script (Also Working with devops-api)
#
use FindBin qw($Bin);
$|=1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
$ins_repo = (!defined($ARGV[0]))?'master':$ARGV[0];
$end_str = '==process complete==';

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	print("You must use the 'rkeuser' account to run the installation script!\n$end_str\n");
	exit;
}

$home_path = '/home/rkeuser';
$nfs_dir = '/iiidevopsNFS';

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

# If /iiidevopsNFS/deploy-config/env.pl exists, the file link is automatically created
$p_config = "$home_path/deploy-devops/env.pl";
if (-e "$nfs_dir/deploy-config/env.pl") {
	$cmd_msg = `ln -s $nfs_dir/deploy-config/env.pl $p_config`; 
	print("env.pl file link is automatically created ..OK!\n");
}
if (-e "$nfs_dir/deploy-config/env.pl.ans") {
	$cmd_msg = `ln -s $nfs_dir/deploy-config/env.pl.ans $p_config.ans`; 
	print("env.pl.ans file link is automatically created ..OK!\n");
}

# Executing Patch
print("Executing Patch Scripts..\n");
system("$Bin/patch/p000.pl");

print("$end_str\n");
exit;
