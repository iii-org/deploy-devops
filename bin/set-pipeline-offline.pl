#!/usr/bin/perl
# Add Secrets & Registry & Catalogs for all Rancher Projects
#
use FindBin qw($Bin);
use MIME::Base64;
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);
require("$Bin/../lib/common_lib.pl");
require("$Bin/../lib/iiidevops_lib.pl");
require("$Bin/../lib/gitlab_lib.pl");

$kubeconf_str = defined($ARGV[0])?'--kubeconfig '.$ARGV[0]:''; 
$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);
$home = "$Bin/../../";

$cmd_kubectl = '/snap/bin/kubectl';
if (!-e $cmd_kubectl) {
	$cmd_kubectl = '/usr/local/bin/kubectl';
}

if (!-e $cmd_kubectl) {
	print("[$cmd_kubectl] is not exist!!!\n");
	exit;
}

$default_ns=`$cmd_kubectl $kubeconf_str get project -n local -o jsonpath="{.items[?(@.spec.displayName=='Default')].metadata.name}"`;
$pipeline_name="$default_ns-pipeline";
$pipeline_ns_check=`$cmd_kubectl $kubeconf_str get ns | grep $pipeline_name`;

if(index($pipeline_ns_check,"Active")>0) {
    $pipeline_check=`$cmd_kubectl $kubeconf_str get deployment -n $pipeline_name`;
    if(index($pipeline_check,"jenkins")>0) {
        $set_pipeline_cmd=<<END;
$cmd_kubectl $kubeconf_str get deployment -n $pipeline_name -o yaml > $home/pipeline.yaml;
sed -i "s/imagePullPolicy\:\ Always/imagePullPolicy\:\ IfNotPresent/g" $home/pipeline.yaml;
$cmd_kubectl $kubeconf_str apply -f $home/pipeline.yaml
END
        system($set_pipeline_cmd);
        $check_set=`$cmd_kubectl $kubeconf_str get deployment -n $pipeline_name -o yaml`;
        if(index($check_set,"imagePullPolicy\:\ Always")<0) {
            $del_crontab=`sed -i '/set-pipeline-offline.pl/d' $home/cron.txt; crontab $home/cron.txt`;
            print("set pipeline Success !!!\n");
        }
    }
}