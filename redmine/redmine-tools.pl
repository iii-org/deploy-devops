#!/usr/bin/perl
# redmine tools script
# redmine-tools <cmd> [base_64_arguments]
#
use FindBin qw($Bin);
use MIME::Base64;
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	json_print('Error', "The configuration file does not exist!");
	exit;
}
require($p_config);
if ($redmine_ip eq '') {
	json_print('Error', "The redmine_ip is ''!");
	exit;
}

# Check parameters
if (!defined($ARGV[0])) {
	json_print('Error', "The command is ''!");
	exit;	
}

require("$Bin/../lib/common_lib.pl");
# Check psql version
chk_psql();
# Query data
$p_cmd = lc($ARGV[0]);
$p_argv = (defined($ARGV[1]))?$ARGV[1]:'';
exec_redmine_data($p_cmd, $p_argv);

exit;

# JSON print
sub json_print {
	my ($p_code, $p_msg) = @_;
	my ($v_tmpl);
	$v_tmpl =<<END;
{
	"code": "%code%",
	"message" : "%msg%"
}
END
	$v_tmpl =~ s/%code%/$p_code/g;
	$v_tmpl =~ s/%msg%/$p_msg/g;

	print("$v_tmpl");
	
	return;
}	

# Check psql version
# psql --version
# psql (PostgreSQL) 12.5 (Ubuntu 12.5-0ubuntu0.20.04.1)
#
sub chk_psql {
	my($v_cmd_msg);
	$v_cmd_msg = `psql --version 2>&1`;
	if (index($v_cmd_msg, '(PostgreSQL) 12')<0) {
		json_print('Error', "psql is not working!");
		exit;
	}
	
	return;
}

# Execute redmine data
# <cmd> <base_64_arguments>
sub exec_redmine_data {
	my ($p_cmd, $p_argv) = @_;
	my ($v_cmd, $v_cmd_msg, $v_argv, $v_chk);

	$v_argv = ($p_argv ne '')?decode_base64($p_argv):'';
	if ($p_cmd eq 'mail_from') {
		$v_cmd_msg = query_data("select value from settings where name='mail_from'");

		#ERROR:  relation "settingxs" does not exist
		#LINE 1: select value from settingxs where name='mail_fromx'
		if (index($v_cmd_msg, 'ERROR:')>=0) {
			json_print('Error', $v_cmd_msg);
			return;
		}

		#trim space & newline
		$v_cmd_msg =~ s/ |\n|\r//g;
		#Nil:
		if ($v_cmd_msg eq '') {
			if ($v_argv ne '') {
				# Insert
				$v_cmd_msg = query_data("insert into settings(name, value, updated_on) values('mail_from', '$v_argv', now())");
				$v_chk = $v_cmd_msg;
				$v_chk =~ s/\n|\r//g;
				if ($v_chk ne 'INSERT 0 1') {
					json_print('Error', "Failed to insert settings! $v_cmd_msg");
					return;
				}
				json_print('OK', "Successfully inserted settings");
				return;
			}
			# GET data
			json_print('OK', '');
			return;
		}
		
		#OK: tech@iiidevops.org
		if ($v_argv ne '') {
			# Update
			$v_cmd_msg = query_data("update settings set value='$v_argv', updated_on=now() where name='mail_from'");
			$v_chk = $v_cmd_msg;
			$v_chk =~ s/\n|\r//g;
			if ($v_chk ne 'UPDATE 1') {
				json_print('Error', "Failed to update settings! $v_cmd_msg");
				return;				
			}
			json_print('OK', "Successfully updated settings");
			return;
		}
		# GET data
		json_print('OK', $v_cmd_msg);
		return;
	}

	json_print('Error', 'Unknown command!');
	return;
}

# Query data
sub query_data {
	my ($p_sql) = @_;
	my ($v_cmd, $v_cmd_msg);

	$v_cmd = "psql -t -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -c \"$p_sql\"";
	$v_cmd_msg = `$v_cmd 2>&1`;

	return($v_cmd_msg);
}
