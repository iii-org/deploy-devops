#!/usr/bin/perl
# update to latest version ISO Patch:
use FindBin qw($Bin);
use JSON::MaybeXS qw(encode_json decode_json);
$|=1; # force flush output

my $p_config = "$Bin/../../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

if ($redmine_ip eq '') {
	print("The redmine_ip in [$p_config] is ''!\n\n");
	exit;
}

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}
#  Update iiidevops core version
$login_cmd = "curl -s -H \"Content-Type: application/json\" --request POST '$iiidevops_api/user/login' --data-raw '{\"username\": \"$admin_init_login\",\"password\": \"$admin_init_password\"}'";
$api_token = decode_json(`$login_cmd`)->{'data'}->{'token'};
$iiidevops_ver_cmd = "curl -s -H \"Content-Type: application/json\" -H \"Authorization: Bearer $api_token\" --request GET '$iiidevops_api/devops_version/check'";
$iiidevops_ver_msg = decode_json(`$iiidevops_ver_cmd`);
if ($iiidevops_ver_msg->{'data'}->{'has_update'}) {
        $update_msg = `curl -s -H \"Content-Type: application/json\" -H \"Authorization: Bearer $api_token\" --request PATCH '$iiidevops_api/devops_version/update'`;
        print($update_msg);
}
$iiidevops_ver = $iiidevops_ver_msg->{'data'}->{'latest_version'}->{'version_name'};

if($iiidevops_ver ne 'develop'){
	$iiidevops_ver = substr($iiidevops_ver,1);
}

# Update Redmine trackers data
$sql = "update trackers set name = 'Fail Management' WHERE id=9";
$sql_cmd = "psql -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -c \"$sql\"";

$cmd =<<END;
cd ~
./deploy-devops/bin/generate_env.pl iiidevops_ver $iiidevops_ver -y;
$sql_cmd;
./deploy-devops/bin/sync_chart_index.pl gitlab_update
END

system($cmd);

# Update kubernetes cluster enable TTL 
$cmd =<<END;
sed -i '/ kube-api:/{:a;n;s/ extra_args: {}/ extra_args:\\n      feature-gates: TTLAfterFinished=true/g;/ kubelet:/!ba}' $nfs_dir/deploy-config/cluster.yml;
rke up --config $nfs_dir/deploy-config/cluster.yml
END

system($cmd);
