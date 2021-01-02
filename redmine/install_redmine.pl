#!/usr/bin/perl
# Install redmine service script
#
use FindBin qw($Bin);
use Digest::SHA qw(sha1_hex);
use Digest::MD5 qw(md5_hex);
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

log_print("Install Redmine URL: http://$redmine_ip:32748\n");
# Deploy Redmine on kubernetes cluster
# Modify redmine/redmine-postgresql/redmine-postgresql.yml.tmpl <- {{redmine_db_passwd}} {{nfs_ip}}
$yaml_path = "$Bin/../redmine/redmine-postgresql/";
$yaml_file = $yaml_path.'redmine-postgresql.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{redmine_db_passwd}}/$redmine_db_passwd/g;
$template =~ s/{{nfs_ip}}/$nfs_ip/g;
$template =~ s/{{nfs_dir}}/$nfs_dir/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy redmine-postgresql..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Modify redmine/redmine/redmine-deployment.yml.tmpl <- {{redmine_db_passwd}}
$yaml_path = "$Bin/../redmine/redmine/";
$yaml_file = $yaml_path.'redmine-deployment.yml';
$tmpl_file = $yaml_file.'.tmpl';
if (!-e $tmpl_file) {
	log_print("The template file [$tmpl_file] does not exist!\n");
	exit;
}
$template = `cat $tmpl_file`;
$template =~ s/{{redmine_db_passwd}}/$redmine_db_passwd/g;
#log_print("-----\n$template\n-----\n\n");
open(FH, '>', $yaml_file) or die $!;
print FH $template;
close(FH);
$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy redmine..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy Redmine service. Please wait.. \n");

# Check Redmine service is working
$cmd = "nc -z -v $redmine_ip 32748";
# Connection to 10.20.0.72 32748 port [tcp/*] succeeded!
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
	log_print("Failed to deploy Redmine!\n");
	log_print("-----\n$cmd_msg-----\n");
	exit;
}
log_print("Successfully deployed Redmine!\n");

# Check psql version
chk_psql();

# import initial data
import_init_data();

exit;

# Check psql version
# psql --version
# psql (PostgreSQL) 12.5 (Ubuntu 12.5-0ubuntu0.20.04.1)
#
# Command 'psql' not found, but can be installed with:
# sudo apt install postgresql-client-common
sub chk_psql {
	$cmd_msg = `psql --version 2>&1`;
	if (index($cmd_msg, '(PostgreSQL) 12')<0) {
		$cmd = "sudo apt install postgresql-client-common postgresql-client-12 -y";
		system($cmd);
	}
	$cmd_msg = `psql --version 2>&1`;
	log_print("Check psql versioon : $cmd_msg");
	if (index($cmd_msg, '(PostgreSQL) 12')<0) {
		log_print("pgsql ..Error!\n\n");
		exit;
	}
	
	return;
}

# import initial data
sub import_init_data {

	$sql_path = "$Bin/../redmine/redmine-postgresql/";
	$sql_file = $sql_path.'redmine-data.sql';
	$tmpl_file = $sql_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$api_key = $redmine_api_key; # 100f750e76fb671a003ee3859825363095e0162e
	$salt = md5_hex($redmine_db_passwd); # 0bdb14a0f8068a7c07fc05b738f1558f
	$hashed_password = sha1_hex($salt.sha1_hex($redmine_admin_passwd)); # 459d496226c2251344c23344fa0aa73a11c2ebee
	$template = `cat $tmpl_file`;
	$template =~ s/{{api_key}}/$api_key/g;
	$template =~ s/{{salt}}/$salt/g;
	$template =~ s/{{hashed_password}}/$hashed_password/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $sql_file) or die $!;
	print FH $template;
	close(FH);
	$cmd = "psql -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -f $sql_file -o $sql_file.log";
	log_print("Import initial data to redmine-postgresql..\n");
	system($cmd);
	$cmd_msg = `cat $sql_file.log`;
	log_print("-----\n$cmd_msg-----\n");

	return;
}

sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}