#!/usr/bin/perl
# Install iiidevops script
#
# Usage: iiidevops_install.pl <local|user@remote_ip>
#
use FindBin qw($Bin);
$|=-1; # force flush output

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0])) {
	print("Usage:	$prgname local \n	$prgname user\@remote_ip\n");
	exit;
}

$ins_repo = (!defined($ARGV[1]))?'master':$ARGV[1];
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check OS version
$cmd_msg = `lsb_release -r`;
$cmd_msg =~ s/\n|\r//g;
($key, $OSVer) = split(/\t/, $cmd_msg);
if ($OSVer ne '20.04') {
	log_print("Only supports Ubuntu 20.04 LTS, your operating system $OSVer is not a supported version\n");
	exit;
}

# Run on remote host 
if (uc($ARGV[0] ne 'local')) {

	$cmd = "ssh $ARGV[0] \"rm -f ./iiidevops_install.pl; wget https://raw.githubusercontent.com/iii-org/deploy-devops/$ins_repo/bin/iiidevops_install.pl; sudo -S perl ./iiidevops_install.pl local $ins_repo\"";
	log_print("Run on $ARGV[0] ...\n");
	$cmd_msg=`$cmd`;
	log_print("-----\n$cmd_msg");
	exit;
}

$cmd = <<END;
cd ~; \
wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip
END
log_print("Getting iiidevops Deploy Package..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo apt update
sudo apt-get install unzip -y;
cd ~; unzip -o $ins_repo.zip;
rm -rf deploy-devops;
mv deploy-devops-$ins_repo deploy-devops;
find ~/deploy-devops -type f -name \"*.pl\" -exec chmod a+x {} \\;
END
log_print("Unziping iiidevops Deploy Package..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

# Check iiidevops_install.pl version
#if ($prgname eq 'iiidevops_install.pl' && -e "$Bin/deploy-devops/bin/$prgname") {
#	($my_md5) = split(/ /, `md5sum $Bin/$prgname`);
#	($dl_md5) = split(/ /, `md5sum $Bin/deploy-devops/bin/$prgname`);
#	if ($my_md5 ne $dl_md5) {
#		log_print("Got the new version of iiidevops_install.pl, execute the downloaded version..\n"); 
#		exec("$Bin/deploy-devops/bin/$prgname local");
#		exit;
#	}
#}

# check /etc/sysctl.conf vm.max_map_count=262144 for Sonarqube
$cmd_msg = `cat /etc/sysctl.conf | grep vm.max_map_count`;
if ($cmd_msg eq '') {
	`echo '########## iiidevops for Sonarqube ##########' | sudo tee -a /etc/sysctl.conf`;
	`echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf`;
	`echo '##########' | sudo tee -a /etc/sysctl.conf`;
	$cmd_msg = `cat /etc/sysctl.conf | grep vm.max_map_count`;
	if (index($cmd_msg, 'vm.max_map_count=262144')<0) {
		log_print("ERROR! Failed to set vm.max_map for Sonarqube, please set it manually!\n");
	}
	else {
		log_print("Successfully set the system parameter vm.max_map for Sonarqube!\n");
		$cmd_msg = `sudo sysctl -w vm.max_map_count=262144`;
		log_print("Enable the system parameter vm.max_map. Result: ".$cmd_msg); 
	}
}
else {
	log_print("The system parameter vm.max_map has been set!\n");
}

# check timezone 
$cmd_msg = `ls -l /etc/localtime`;
if (index($cmd_msg, 'Taipei')<0) {
	$cmd = "sudo cp /etc/localtime /tmp/old.timezone;sudo rm -f /etc/localtime;sudo ln -s /usr/share/zoneinfo/Asia/Taipei /etc/localtime; date";
	$cmd_msg = `$cmd`;
	#Thu Jan 28 16:55:27 CST 2021
	if (index($cmd_msg, 'CST')<0) {
		log_print("Set Time zone Error!\n$cmd_msg\n-----\n");
		exit;
	}
	log_print("Successfully set the time zone to Taipei!\n");	
}
else {
	log_print("Time zone has been set to Taipei!\n");
}

$cmd = <<END;
sudo apt-get update -y;
sudo apt-get install nfs-common libterm-readkey-perl libjson-maybexs-perl postgresql-client-common postgresql-client-12 apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y;
END
log_print("Install default packages..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\";
sudo apt-get update -y;
sudo apt-get install docker-ce=5:19.03.14~3-0~ubuntu-focal docker-ce-cli=5:19.03.14~3-0~ubuntu-focal containerd.io -y;
END
log_print("Install docker..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo snap install kubectl --channel=1.18/stable --classic; 
sudo snap install helm --channel=3.5/stable --classic; 
mkdir -p ~/.kube/;
END
log_print("Install kubectl and helm..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

# Validation results
log_print("\n-----Validation results-----\n");

#check docker version
#Docker version 19.03.14, build 5eb3275d40
$chk_str = '19.03.14';
$cmd = "docker -v";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install docker Failed! : $cmd_msg");
}
else {
	log_print("Install docker $chk_str ..OK!\n");
}

#check kubectl version
#Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.14", GitCommit:"89182bdd065fbcaffefec691908a739d161efc03", GitTreeState:"clean", BuildDate:"2020-12-22T14:49:29Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
$chk_str = 'v1.18';
$cmd = "kubectl version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install kubectl Failed!\n$cmd_msg");
}
else {
log_print("Install kubectl $chk_str ..OK!\n");
}

#check helm version
#version.BuildInfo{Version:"v3.5.0", GitCommit:"32c22239423b3b4ba6706d450bd044baffdcf9e6", GitTreeState:"clean", GoVersion:"go1.15.6"}
$chk_str = 'v3.5';
$cmd = "helm version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install helm Failed!\n$cmd_msg");
}
else {
	log_print("Install helm $chk_str ..OK!\n");
}

# If /iiidevopsNFS/deploy-config/env.pl exists, the file link is automatically created
$nfs_dir = '/iiidevopsNFS';
$p_config = "$Bin/deploy-devops/env.pl";
if (-e "$nfs_dir/deploy-config/env.pl") {
	$cmd_msg = `ln -s $nfs_dir/deploy-config/env.pl $p_config`; 
	log_print("env.pl file link is automatically created ..OK!\n");
}
if (-e "$nfs_dir/deploy-config/env.pl.ans") {
	$cmd_msg = `ln -s $nfs_dir/deploy-config/env.pl.ans $p_config.ans`; 
	log_print("env.pl.ans file link is automatically created ..OK!\n");
}


exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}

