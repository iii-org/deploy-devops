#!/usr/bin/perl
use Socket;
use Sys::Hostname;

my $p_config = '../env.pl';
if (-e $p_config) {
	require($p_config);
}

if (!defined($gitlab_url) || $gitlab_url eq '') {
	my $host = hostname();
	$gitlab_url = inet_ntoa(scalar gethostbyname($host || 'localhost'));
}

print("Install GitLab URL: http://$gitlab_url\n");
$cmd="sudo docker run --env GITLAB_OMNIBUS_CONFIG=\"external_url 'http://$gitlab_url';\"  --detach --publish 443:443 --publish 80:80 --publish 10022:22 --name gitlab --restart always --volume $HOME/gitlab/config:/etc/gitlab --volume $HOME/gitlab/logs:/var/log/gitlab --volume $HOME/gitlab/data:/var/opt/gitlab gitlab/gitlab-ce:12.10.6-ce.0";
print("-----\n$cmd\n\n");

$cmd_msg = `$cmd`;
print("-----\n$cmd_msg\n\n");
