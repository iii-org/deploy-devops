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

# Rancher 2.6.x support version
$os_ver = '20.04';
$rke_ver = 'v1.3.0';
$docker_ver = '20.10.';
$kubectl_ver = 'v1.20.10';

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

# check running path
$home_path = '/home/rkeuser';
if ($Bin ne $home_path) {
	log_print("You must run the installation script in [$home_path]!\n");
	exit;
}

# Use rke version to confirm compatibility
$rke_cmd = '/usr/local/bin/rke';
if (-e $rke_cmd) {
	$cmd = "$rke_cmd --version";
	$cmd_msg = `$cmd 2>&1`;
	if (index($cmd_msg, $rke_ver)<0) {
		log_print("The installed base system version is incompatible and needs to be upgraded manually!\n$cmd_msg");
		exit;
	}
}

# Check OS version
$cmd_msg = `lsb_release -r`;
$cmd_msg =~ s/\n|\r//g;
($key, $OSVer) = split(/\t/, $cmd_msg);
if ($OSVer ne $os_ver) {
	$cmd_msg = `cat /etc/issue`;
	log_print("Only supports Ubuntu $os_ver LTS, your operating system : $cmd_msg");
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
if (!-e "$home_path/update-perl.pl") {
	system("cd $home_path; wget -O update-perl.pl https://raw.githubusercontent.com/iii-org/deploy-devops/master/bin/update-perl.pl");
}
$cmd = "perl $home_path/update-perl.pl $ins_repo";
log_print("Install iiidevops Deploy Scripts..\n");
system($cmd);

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
sudo apt-get install docker-ce=5:$docker_ver* docker-ce-cli=5:$docker_ver* containerd.io -y;
END
#check docker version
$chk_str = $docker_ver;
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
curl -LO https://dl.k8s.io/release/$kubectl_ver/bin/linux/amd64/kubectl;
sudo chmod a+x kubectl;
sudo mv ./kubectl /usr/local/bin/;
mkdir -p $home_path/.kube/;
END
#check kubectl version
$chk_str = $kubectl_ver;
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
wget -O rke https://github.com/rancher/rke/releases/download/$rke_ver/rke_linux-amd64
sudo mv rke $rke_cmd
sudo chmod +x $rke_cmd
END
#check rke version
$chk_str = $rke_ver;
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
$chk_str = $docker_ver;
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
$chk_str = $kubectl_ver;
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
$chk_str = $rke_ver;
$cmd = "rke --version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install rke Failed!\n$cmd_msg");
}
else {
	log_print("Install rke $chk_str ..OK!\n");
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
