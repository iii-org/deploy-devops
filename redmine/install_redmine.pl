#!/usr/bin/perl
# Install redmine service script
#
use FindBin qw($Bin);
use Digest::SHA qw(sha1_hex);
use Digest::MD5 qw(md5_hex);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($redmine_ip eq '') {
	print("The redmine_ip in [$p_config] is ''!\n\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# Check Redmine service is working
if (get_service_status('redmine')) {
	log_print("Redmine is running, I skip the installation!\n\n");
	exit;
}
log_print("Install Redmine ..\n");

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

# Modify redmine/redmine/redmine-ingress.yaml.tmpl <- {{redmine_domain_name}}
$yaml_path = "$Bin/../redmine/redmine/";
$yaml_file = $yaml_path.'redmine-ingress.yml';
if ($redmine_domain_name ne '' && uc($deploy_mode) ne 'IP') {
	$tmpl_file = $yaml_file.'.tmpl';
	if (!-e $tmpl_file) {
		log_print("The template file [$tmpl_file] does not exist!\n");
		exit;
	}
	$template = `cat $tmpl_file`;
	$template =~ s/{{redmine_domain_name}}/$redmine_domain_name/g;
	#log_print("-----\n$template\n-----\n\n");
	open(FH, '>', $yaml_file) or die $!;
	print FH $template;
	close(FH);
}
else {
	$cmd = "rm -f $yaml_file";
	$cmd_msg = `$cmd 2>&1`;
	if ($cmd_msg ne '') {
		log_print("$cmd Error!\n$cmd_msg-----\n");
	}
}

# redmine-config.yaml
$yaml_file = $yaml_path.'redmine-config.yaml';
$cmd = "kubectl apply -f $yaml_file";
$cmd_msg = `$cmd 2>&1`;
if (index($cmd_msg, 'error:')>=0) {
	log_print("Failed to deploy redmine config!\n$cmd_msg\n");
	exit;
}
log_print("Deploy redmine config..\n$cmd_msg\n");

# Check Redmine config is working
$isChk=1;
$count=0;
$wait_sec=90;
$cmd = "kubectl get configmap | grep redmine-config";
$chk_key = 'redmine-config ';
while($isChk && $count<$wait_sec) {
	log_print('.');
	$cmd_msg = `$cmd 2>&1`;
	$isChk = (index($cmd_msg, $chk_key)<0)?1:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy Redmine config!\n");
	exit;
}
log_print("Deploy redmine config OK!\n");

$cmd = "kubectl apply -f $yaml_path";
log_print("Deploy redmine..\n");
$cmd_msg = `$cmd`;
log_print("-----\n$cmd_msg-----\n");

# Display Wait 3 min. message
log_print("It takes 1 to 3 minutes to deploy Redmine service. Please wait.. \n");

# Check Redmine service is working
$isChk=1;
$count=0;
$wait_sec=600;
while($isChk && $count<$wait_sec) {
	log_print('.');
	$isChk = (!get_service_status('redmine'))?3:0;
	$count = $count + $isChk;
	sleep($isChk);
}
log_print("\n");
if ($isChk) {
	log_print("Failed to deploy Redmine!\n");
	exit;
}
$the_url = get_domain_name('redmine');
log_print("Successfully deployed Redmine! URL - http://$the_url\n");

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
	$the_host_name = get_domain_name('iiidevops');
	$template = `cat $tmpl_file`;
	$template =~ s/{{api_key}}/$api_key/g;
	$template =~ s/{{salt}}/$salt/g;
	$template =~ s/{{hashed_password}}/$hashed_password/g;
	$template =~ s/{{devops_domain_name}}/$the_host_name/g;	
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
