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

$cmd = "cd ~; wget -O $ins_repo.zip https://github.com/iii-org/deploy-devops/archive/$ins_repo.zip";
log_print("Getting iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
#log_print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo apt-get install unzip nfs-common libterm-readkey-perl -y";
$cmd .= "; cd ~; unzip -o -d deploy-devops $ins_repo.zip";
$cmd .= "; cd deploy-devops-$ins_repo/";
$cmd .= "; chmod a+x bin/*.sh";
$cmd .= "; chmod a+x bin/*.pl";
$cmd .= "; chmod a+x gitlab/*.pl";
$cmd .= "; chmod a+x harbor/*.pl";
log_print("Unziping iiidevops Deploy Package..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo apt-get update -y ";
$cmd .= "; sudo apt-get install apt-transport-https ca-certificates curl gnupg-agent software-properties-common -y ";
$cmd .= "; curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ";
$cmd .= "; sudo add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" "; 
$cmd .= "; sudo apt-get update -y ";
$cmd .= "; sudo apt-get install docker-ce docker-ce-cli containerd.io -y ";
$cmd .= "; usermod -aG docker \$SUDO_USER ";
$cmd .= "; docker -v";
log_print("Install docker..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg\n-----\n");

$cmd = "sudo snap install kubectl --classic";
$cmd .= "; mkdir -p ~/.kube/";
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

