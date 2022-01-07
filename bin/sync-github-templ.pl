#!/usr/bin/perl
# sync github project script
#
# Usage: sync-github-templ.pl [github_id:github_token]
#
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if (!defined($ARGV[0])) {
    print("Please setting github_token!\n");
    exit;
}

$github_user_token = $ARGV[0];
($cmd_msg, $github_token) = split(':', $github_user_token);
if (length($github_token)!=40) {
	print("github_token:[$github_token] is worng!\n");
	exit;
}

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");

log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

if (validate_guthub_token()) {
    log_print("validate token success\n");
    
    # sync env github toke
    if ($sync_templ_key ne $github_user_token) {
        system("perl $Bin/generate_env.pl sync_templ_key $github_user_token -y");
        log_print("sync env sync_templ_key to $github_user_token \n");
    }
}
elsif ($validate_token_msg->{'message'} ne '') {
	log_print("validate token fail : $validate_token_msg->{'message'}\n");
    $error_msg = encode_json($validate_token_msg->{'error'});
	sed_alert_msg($error_msg);
	exit;
}
else {
    log_print("api error : ".$validate_token_msg->{'msg'}."\n");
	exit;
}

system("perl $Bin/sync-prj-templ.pl");
log_print("sync github iiidevops-templates... SUCCESS\n");
log_print("----------------------------------------\n");
system("perl $Bin/sync_chart_index.pl gitlab_update");
log_print("sync sync github chart templates... SUCCESS\n");
