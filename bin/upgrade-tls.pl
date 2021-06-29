#!/usr/bin/perl
# Upgrade using TLS script
#
use FindBin qw($Bin);
$|=1; # force flush output

my $p_config = "$Bin/../env.pl";
if (!-e $p_config) {
	print("The configuration file [$p_config] does not exist!\n");
	exit;
}
require($p_config);

$prgname = substr($0, rindex($0,"/")+1);
$logfile = "$Bin/$prgname.log";
require("$Bin/../lib/common_lib.pl");
log_print("\n----------------------------------------\n");
log_print(`TZ='Asia/Taipei' date`);

# GitLab
if ($gitlab_domain_name_tls ne '') {
	system("$Bin/../gitlab/install_gitlab.pl force");
}

# K8s
if ($ingress_domain_name_tls ne '') {
	system("$Bin/../kubernetes/install_k8s.pl manual_secret_tls");
}

# Rancher
if ($ingress_domain_name_tls ne '') {
	system("$Bin/../rancher/install_rancher.pl manual_secret_tls");
}

# Harbor
if ($ingress_domain_name_tls ne '') {
	system("$Bin/../harbor/install_harbor.pl manual_secret_tls");
}

# Redmine
if ($ingress_domain_name_tls ne '') {
	system("$Bin/../redmine/install_redmine.pl force");
}

# SonarQube
if ($ingress_domain_name_tls ne '') {
	system("$Bin/../sonarqube/install_sonarqube.pl force");
}

# III DevOps
# If the installation has not been completed, the length of $gitlab_private_token should not be 20, so skip this step.
if ($ingress_domain_name_tls ne '' && length($gitlab_private_token)==20) {
	system("$Bin/iiidevops_install_core.pl");
}
