#!/usr/bin/perl
use FindBin qw($Bin);
my $p_config = "$Bin/../env.pl";
if (-e $p_config) {
	require($p_config);
}
else {
	print("Cannot find configuration setting information file '$p_config'! \n");
	exit;
}

print("Install GitLab URL: http://$gitlab_ip\n");
$cmd =
"sudo docker run --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://$gitlab_ip';\"  --detach --publish 443:443 --publish 80:80 --publish 10022:22 --name gitlab --restart always --volume $data_dir/gitlab/config:/etc/gitlab --volume $data_dir/gitlab/logs:/var/log/gitlab --volume $data_dir/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:12.10.6-ce.0";
print("-----\n$cmd\n\n");

$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");
