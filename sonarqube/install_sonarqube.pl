#!/usr/bin/perl
# Install sonarqube service script
#
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

log_print("Install Sonarqube URL: http://$sonarqube_ip:31910\n");
# Deploy Sonarqube on kubernetes cluster

# Modify sonarqube/sonarqube-postgresql/sonarqube-postgresql.yml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube-postgresql";
$yaml_file = $yaml_path.'/sonarqube-postgresql.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_db_passwd}}/$sonarqube_db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy sonarqube-postgresql..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");


# Modify sonarqube/sonarqube/sonar-server-deployment.yaml.tmpl
$yaml_path = "$Bin/../sonarqube/sonarqube";
$yaml_file = $yaml_path.'/sonar-server-deployment.yaml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{sonarqube_db_passwd}}/$sonarqube_db_passwd/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy sonarqube..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy Sonarqube service. Please wait.. \n");

# Check Sonarqube service is working
$cmd = "nc -z -v $sonarqube_ip 31910";
# Connection to 10.20.0.72 31910 port [tcp/*] succeeded!
$chk_key = 'succeeded!';
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count ++;
	sleep($isChk);
}
log_print("\n$cmd_msg-----\n");
if ($isChk) {
	log_print("Failed to deploy Sonarqube!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Sonarqube!\n");
exit;


sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}