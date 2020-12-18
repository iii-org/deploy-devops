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

print("Install GitLab URL: http://$gitlab_url\n");
$cmd =
"sudo docker run --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://$gitlab_url';\"  --detach --publish 443:443 --publish 80:80 --publish 10022:22 --name gitlab --restart always --volume $HOME/gitlab/config:/etc/gitlab --volume $HOME/gitlab/logs:/var/log/gitlab --volume $HOME/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:12.10.6-ce.0";
print("-----\n$cmd\n\n");

$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");
