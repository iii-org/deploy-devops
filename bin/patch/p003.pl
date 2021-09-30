#!/usr/bin/perl
# update to V1.7.1 ISO Patch:
use FindBin qw($Bin);
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

# Update Redmine trackers data
$sql = "update trackers set name = 'Fail Management' WHERE id=9";
$sql_cmd = "psql -d 'postgresql://postgres:$redmine_db_passwd\@$redmine_ip:32749/redmine' -c \"$sql\"";

$cmd =<<END;
cd ~
./deploy-devops/bin/generate_env.pl iiidevops_ver 1.9.1 -y;
./deploy-devops/bin/iiidevops_install_core.pl;
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
