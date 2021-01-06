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

# Check iiidevops_install.pl version
if ($prgname eq 'iiidevops_install.pl') {
	($my_md5) = split(/ /, `md5sum $Bin/$prgname`);
	($dl_md5) = split(/ /, `md5sum $Bin/deploy-devops/bin/$prgname`);
	if ($my_md5 ne $dl_md5) {
		log_print("Got the new version of iiidevops_install.pl, execute the downloaded version..\n"); 
		exec("$Bin/deploy-devops/bin/$prgname local");
		exit;
	}
}

$cmd = <<END;
sudo apt-get install unzip nfs-common libterm-readkey-perl libjson-maybexs-perl postgresql-client-common postgresql-client-12 -y;
cd ~; unzip -o $ins_repo.zip;
rm -rf deploy-devops;
mv deploy-devops-$ins_repo deploy-devops;
find ~/deploy-devops -type f -name \"*.pl\" -exec chmod a+x {} \\;
END
log_print("Unziping iiidevops Deploy Package..\n");
#$cmd_msg = `$cmd`;
system($cmd);
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo apt-get update -y;
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y;
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
mkdir -p ~/.kube/;
END
log_print("Install kubectl..\n");
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
log_print("Install docker $chk_str ..OK!\n");

#check kubectl version
#Client Version: version.Info{Major:"1", Minor:"18", GitVersion:"v1.18.14", GitCommit:"89182bdd065fbcaffefec691908a739d161efc03", GitTreeState:"clean", BuildDate:"2020-12-22T14:49:29Z", GoVersion:"go1.13.15", Compiler:"gc", Platform:"linux/amd64"}
$chk_str = 'v1.18';
$cmd = "kubectl version";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, $chk_str)<0) {
	log_print("Install kubectl Failed!\n$cmd_msg");
}
log_print("Install kubectl $chk_str ..OK!\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}

