#!/usr/bin/perl
# 2022/5/5
# Redmine update settings table
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../../env.pl";
if (!-e $p_config) {
	print("Error! The configuration file [$p_config] does not exist!\n");
	exit(1);
}
require($p_config);
require("$Bin/../../lib/iiidevops_lib.pl");

# Update Redmine settings data
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	print("Error! You must use the 'rkeuser' account to run the installation script!\n");
	exit(1);
}
my %hash = (
			'cross_project_issue_relations' => '1',
			'link_copied_issue' => 'ask',
			'cross_project_subtasks' => 'tree',
			'close_duplicate_issues' => '1',
			'issue_group_assignment' => '1',
			'default_issue_start_date_to_creation_date' => '1',
			'display_subprojects_issues' => '1',
			'issue_done_ratio' => 'issue_field',
			'non_working_week_days' => "---\n- ''6''\n- ''7''\n",
			'issues_export_limit' => '500',
			'gantt_items_limit' => '500',
			'gantt_months_limit' => '24',
			'parent_issue_dates' => 'derived',
			'parent_issue_priority' => 'derived',
			'parent_issue_done_ratio' => 'derived',
			'issue_list_default_columns' => "---\n- tracker\n- status\n- priority\n- subject\n- assigned_to\n- updated_on\n",
			'issue_list_default_totals' => "--- []\n",
			);
$sql = "SELECT * from \"settings\" WHERE (";
$count=0;
while (my ($key, $value) = each (%hash)) {
	if($count == 0){
		$sql = "$sql \"name\"='$key'";
	}else{
		$sql = "$sql OR \"name\"='$key'"
	}
	$count ++;
}
$sql = "$sql)";
$sql_cmd = `psql -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -c \"$sql\"`;

if(index($sql_cmd,"FATAL")>=0){
	print("$sql_cmd\n");
	exit(1);
}

$count=0;
$create_sql="INSERT INTO public.settings (name,value,updated_on) VALUES";
$update_sql="";
while (my ($key, $value) = each (%hash)) {
	if(index($sql_cmd,$key) < 0){
		if($count != 0){
			$create_sql="$create_sql,";
		}
		$create_sql="$create_sql (\'$key\',\'$value\',now())";
		$count++;
	}else{
		$update_sql="$update_sql UPDATE \"settings\" SET \"value\" = '$value' WHERE \"name\" = '$key';";
	}
}
if($count != 0) {
	$sql="$create_sql;$update_sql";
}else{
	$sql=$update_sql;
}
$sql_cmd = `psql -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -c \"$sql\"`;

exit;