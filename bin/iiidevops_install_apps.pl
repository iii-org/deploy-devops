#!/usr/bin/perl
# Install iiidevops applications script
#
use Socket;
use Sys::Hostname;

my $p_config = '../env.pl';
if (-e $p_config) {
	require($p_config);
}

if (!defined($nfs_ip) || $nfs_ip eq '') {
	my $host = hostname();
	$nfs_ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));
}

# Deploy Redmine on kubernetes cluster
# Modify redmine/redmine-postgresql/redmine-postgresql.yml.tmpl <- {{postgres_password}} {{nfs_ip}}
$cmd = "kubectl apply -f redmine/redmine-postgresql/";
# Modify redmine/redmine/redmine-deployment.yml.tmpl <- {{postgres_password}}
$cmd = "kubectl apply -f redmine/redmine/";

# Deploy SonarQube Server on kubernetes cluster
# Modify sonarqube/sonar-server-deployment.yaml.tmpl <- {{nfs_ip}}

# Deploy DevOps DB (Postgresql) on kubernetes cluster
# Modify devops-db/devopsdb-deployment.yaml.tmpl <- {{postgres_password}}

# Deploy DevOps API (Python Flask) on kubernetes cluster
# Modify devops-api/_devopsapi-deployment.yaml.tmpl <- {{postgres_password}} {{db_ip}} ... {{gitlab_url}}

# Deploy DevOps UI (VueJS) on kubernetes cluster

