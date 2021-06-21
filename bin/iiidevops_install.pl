#!/usr/bin/perl
# Install iiidevops script
#
# Usage: iiidevops_install.pl
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

# Check OS version
$cmd_msg = `lsb_release -r`;
$cmd_msg =~ s/\n|\r//g;
($key, $OSVer) = split(/\t/, $cmd_msg);
if ($OSVer ne '20.04') {
	$cmd_msg = `cat /etc/issue`;
	log_print("Only supports Ubuntu 20.04 LTS, your operating system : $cmd_msg");
	exit;
}

# Install OS Packages
$cmd = <<END;
sudo apt update
sudo apt-get install unzip nfs-common nfs-kernel-server libterm-readkey-perl libjson-maybexs-perl postgresql-client-common postgresql-client apt-transport-https ca-certificates curl gnupg-agent software-properties-common snap -y;
END
log_print("Install OS Packages..\n");
system($cmd);

# Install iiidevops Deploy Scripts
$cmd = <<END;
cd ~;
wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip
unzip -o $ins_repo.zip;
rm -rf deploy-devops;
mv deploy-devops-$ins_repo deploy-devops;
find ~/deploy-devops -type f -name \"*.pl\" -exec chmod a+x {} \\;
END
log_print("Install iiidevops Deploy Scripts..\n");
system($cmd);

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

# Disable swap
$cmd = <<END;
sudo swapoff -a;
sudo sed -ri '/\\sswap\\s/s/^#?/#/' /etc/fstab;
END
log_print("Disable swap..\n");
system($cmd);

# Install docker
$cmd = <<END;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -;
sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\";
sudo apt-get update -y;
sudo apt-get install docker-ce=5:19.03.14~3-0~ubuntu-focal docker-ce-cli=5:19.03.14~3-0~ubuntu-focal containerd.io -y;
END
#check docker version
#Docker version 19.03.14, build 5eb3275d40
$chk_str = '19.03.14';
$cmd_msg = `docker -v 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install docker..\n");
	system($cmd);
}
else {
	log_print("docker was Installed..$chk_str\n");
}

# Install kubectl
$cmd = <<END;
curl -LO https://dl.k8s.io/release/v1.18.17/bin/linux/amd64/kubectl;
sudo chmod a+x kubectl;
sudo mv ./kubectl /usr/local/bin/;
mkdir -p ~/.kube/;
END
#check kubectl version
#Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.14", GitCommit:"89182bdd065fbcaffefec691908a739d161efc03", GitTreeState:"clean", BuildDate:"2020-12-22T14:49:29Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
$chk_str = 'v1.18';
$cmd_msg = `kubectl version 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install kubectl..\n");
	system($cmd);
}
else {
	log_print("kubectl was Installed..$chk_str\n");
}

# Install helm
$cmd = <<END;
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -;
sudo apt-get install apt-transport-https --yes;
echo \"deb https://baltocdn.com/helm/stable/debian/ all main\" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
END
#check helm version
#version.BuildInfo{Version:"v3.5.0", GitCommit:"32c22239423b3b4ba6706d450bd044baffdcf9e6", GitTreeState:"clean", GoVersion:"go1.15.6"}
$chk_str = 'Version';
$cmd_msg = `helm version 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install helm..\n");
	system($cmd);
}
else {
	log_print("helm was Installed..\n");
}

# Install rke
$cmd = <<END;
wget -O rke https://github.com/rancher/rke/releases/download/v1.2.7/rke_linux-amd64
sudo mv rke /usr/local/bin/rke
sudo chmod +x /usr/local/bin/rke
END
#check rke version
#rke version v1.2.7
$chk_str = 'v1.2.7';
$cmd_msg = `rke --version 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install rke..\n");
	system($cmd);
}
else {
	log_print("rke was Installed..$chk_str\n");
}


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

$cmd = "sudo usermod -aG docker rkeuser";
$cmd_msg = `$cmd 2>&1`;
if ($cmd_msg ne ''){
	log_print("Unable to set the permission of 'rkeuser' to run docker! : $cmd_msg");
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
$chk_str = 'Version';
$cmd = "helm version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install helm Failed!\n$cmd_msg");
}
else {
	log_print("Install helm ..OK!\n");
}

#check rke version
#rke version v1.2.7
$chk_str = 'v1.2.7';
$cmd = "rke --version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install rke Failed!\n$cmd_msg");
}
else {
	log_print("Install rke $chk_str ..OK!\n");
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
