#!/usr/bin/perl
# Install iiidevops script
#
# Usage: iiidevops_install.pl <local|user@remote_ip>
#
use FindBin qw($Bin);

$prgname = substr($0, rindex($0,"/")+1);
if (!defined($ARGV[0])) {
	print("Usage: $prgname local or $prgname user\@remote_ip\n");
	exit;
}

$ins_repo = (!defined($ARGV[1]))?'master':$ARGV[1];
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Run on remote host 
if (uc($ARGV[0] ne 'local')) {

	$cmd = "ssh $ARGV[0] \"wget https://raw.githubusercontent.com/iii-org/deploy-devops/$ins_repo/bin/iiidevops_install.pl; sudo -S perl ./iiidevops_install.pl local $ins_repo\"";
	log_print("Run on $ARGV[0] ...\n");
	$cmd_msg=`$cmd`;
	log_print("-----\n$cmd_msg\n-----\n");
	exit;
}

$cmd = <<END;
cd ~; \
wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip
END
log_print("Getting iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo apt-get install unzip nfs-common libterm-readkey-perl -y; \
cd ~; unzip -o $ins_repo.zip \
rm -rf deploy-devops \
mv deploy-devops-$ins_repo deploy-devops \
cd deploy-devops/ \
chmod a+x bin/*.sh \
chmod a+x bin/*.pl \
chmod a+x gitlab/*.pl \
chmod a+x harbor/*.pl
END
log_print("Unziping iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo apt-get update -y; \
sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y
END
log_print("Install default packages..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -; \
sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\"; \ 
sudo apt-get update -y; \
sudo apt-get install docker-ce docker-ce-cli containerd.io -y; \
usermod -aG docker \$SUDO_USER; \
docker -v
END
log_print("Install docker..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd = <<END;
sudo snap install kubectl --classic; \
mkdir -p ~/.kube/
END
log_print("Install kubectl..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

exit;

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}

