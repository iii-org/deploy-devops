#!/usr/bin/perl
# Get cluster node dockerhub pull ratelimit info
#
use JSON::MaybeXS qw(encode_json decode_json);
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
$prgname = substr($0, rindex($0,"/")+1);
$kubeconf_str = defined($ARGV[0])?'--kubeconfig '.$ARGV[0]:'';

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("[$cmd_kubectl] is not exist!!!\n");
	exit;
}

$cmd = "$cmd_kubectl $kubeconf_str get node -o wide | awk 'NR!=1 {print \$6}'";
$cmd_msg = `$cmd`;
$data ='[';
foreach $node (split(/\n/, $cmd_msg)) {
    $p_pl = `ssh -o \"StrictHostKeyChecking no\" -q $node test -f $Bin/get-dockerhub-pull-ratelimit.pl && echo found || echo not found`;
    if (index($p_pl, 'not found')>=0) {
        print("[$Bin/get-dockerhub-pull-ratelimit.pl] is not exist!!!\n");
        print("sned get-dockerhub-pull-ratelimit.pl to Host[$node]\n");
        $get_perl = `scp -o \"StrictHostKeyChecking no\" $Bin/get-dockerhub-pull-ratelimit.pl $node:$Bin/get-dockerhub-pull-ratelimit.pl`;
    }
    $pull_limit_cmd = "ssh -o \"StrictHostKeyChecking no\" $node perl $Bin/get-dockerhub-pull-ratelimit.pl";
    $pull_limit_msg = `$pull_limit_cmd`;
    $data .= "{\"node\":\"$node\"";
    # print($pull_limit_msg);
    if (index($pull_limit_msg, '200 OK')>=0) {
        @ratelimit_limit = split(';',`echo '$pull_limit_msg' | grep ratelimit-limit`);
        @ratelimit_limit = split(': ',$ratelimit_limit[0]);
        @ratelimit_remaining = split(';',`echo '$pull_limit_msg' | grep ratelimit-remaining`);
        @ratelimit_remaining = split(': ',$ratelimit_remaining[0]);
        @source = split(': ',`echo '$pull_limit_msg' | grep docker-ratelimit-source`);
        $data .= ",\"ratelimit-limit\":$ratelimit_limit[1],";
        $data .= "\"ratelimit-remaining\":$ratelimit_remaining[1],";
        $data .= "\"docker-ratelimit-source\":\"$source[1]\"";
    }
    $data .= "},";
}
print("---\n");
$data = substr($data,0,length($data)-1);
$data .=']';
$data =~ s/\n|\r//g;
print("$data\n");