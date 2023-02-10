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

# Fix branch v2 : deploy-devops-2 issue
$fixed_ins_repo = $ins_repo;
if ($fixed_ins_repo =~ /^v\d/) {
	$fixed_ins_repo =~ s/^.//;
}

# Install iiidevops Deploy Scripts
$cmd = <<END;
cd $home_path;
wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip
unzip -o $ins_repo.zip;
rm -rf deploy-devops;
mv deploy-devops-$fixed_ins_repo deploy-devops;
find $home_path/deploy-devops -type f -name \"*.pl\" -exec chmod a+x {} \\;
END
print("Install iiidevops Deploy Scripts..\n");
system($cmd);

# Get Zip hash
$zip_hash = `md5sum $home_path/$ins_repo.zip`;

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
if (-e "$nfs_dir/sbom/sbom_license") {
	$cmd_msg = `mkdir $home_path/deploy-devops/sbom;ln -s $nfs_dir/sbom/sbom_license $home_path/deploy-devops/sbom/sbom_license`; 
	print("sbom  file link is automatically created ..OK!\n");
}

# Check ins_repo.zip hash info
$hash_info_file = $home_path.'/'.$ins_repo.'.md5';
if (-e $hash_info_file) {
	$hash_info = `cat $hash_info_file`;
	if ($hash_info eq $zip_hash) {
		print("The version is the same, no need to perform the following steps.\n");
		print("$end_str\n");
		exit;
	}
}

# Executing Patch
print("Executing Patch Scripts..\n");
$run_patch = system("$Bin/patch/p000.pl") >> 8;
print("\nrun patch error: $run_patch\n");
if ($run_patch) {
	print("Error! Update run patch fail !\n");
	exit;
}
print("$end_str\n");

# Write hash_info
open(FH, '>', $hash_info_file) or die $!;
print FH $zip_hash;
close(FH);
exit;
