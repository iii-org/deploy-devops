#!/usr/bin/perl
# Get cluster node df disk info
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
    $df_cmd = "ssh -o \"StrictHostKeyChecking no\" $node df -h| grep \"/\$\"";
    $df_cmd_msg = `$df_cmd`;
    $data .= "{\"node\":\"$node\"";
    @df = split(' ',$df_cmd_msg);
    $data .= ",\"Filesystem\":\"$df[0]\",";
    $data .= "\"Size\":\"$df[1]\",";
    $data .= "\"Used\":\"$df[2]\",";
    $data .= "\"Avail\":\"$df[3]\",";
    $data .= "\"Usage\":\"$df[4]\",";
    $data .= "\"Mounted\":\"$df[5]\"";
    $data .= "},";
}
$data = substr($data,0,length($data)-1);
$data .=']';
$data =~ s/\n|\r//g;
print("$data\n");