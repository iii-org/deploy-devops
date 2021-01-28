#!/usr/bin/perl
# common lib
#

# Deploy Mode $deploy_mode = # IP(Default), DNS, nip.io, xip.io
# $p_service : gitlab, redmine, harbor, sonaqrqube, iiidevops
# Exp.
#   IP : 10.20.0.73
#		gitlab		10.20.0.73:32080
#		redmine		10.20.0.73:32748
#		harbor		10.20.0.73:32443
#		sonaqrqube	10.20.0.73:31910
#		iiidevops	10.20.0.73:30775
#	DNS : 
#		gitlab		gitlab.iiidevops.org
#		redmine		redmine.iiidevops.org
#		harbor		harbor.iiidevops.org
#		sonaqrqube	sonaqrqube.iiidevops.org
#		iiidevops	www.iiidevops.org
#	nip.io
#		gitlab		gitlab.iiidevops.10.20.0.73.nip.io
#		redmine		redmine.iiidevops.10.20.0.73.nip.io
#		harbor		harbor.iiidevops.10.20.0.73.nip.io
#		sonaqrqube	sonaqrqube.iiidevops.10.20.0.73.nip.io
#		iiidevops	iiidevops.10.20.0.73.nip.io
#	xip.io
#		gitlab		gitlab.iiidevops.10.20.0.73.xip.io
#		redmine		redmine.iiidevops.10.20.0.73.xip.io
#		harbor		harbor.iiidevops.10.20.0.73.xip.io
#		sonaqrqube	sonaqrqube.iiidevops.10.20.0.73.xip.io
#		iiidevops	iiidevops.10.20.0.73.xip.io
#
sub get_domain_name {
	my ($p_service) = @_;
	my ($v_domain_name);
	
	$v_domain_name = '';
	if (uc($deploy_mode) eq 'DNS') {
		if ($p_service eq 'gitlab') {
			$v_domain_name = $gitlab_domain_name;
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = $redmine_domain_name;
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = $harbor_domain_name;
		}
		elsif ($p_service eq 'sonaqrqube') {
			$v_domain_name = $sonarqube_domain_name;
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = $iiidevops_domain_name;
		}
	}
	elsif (lc($deploy_mode) eq 'nip.io') {
		if ($p_service eq 'gitlab') {
			$v_domain_name = 'gitlab.iiidevops.'.$gitlab_ip.'.nip.io';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = 'gitlab.iiidevops.'.$redmine_ip.'.nip.io';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = 'gitlab.iiidevops.'.$harbor_ip.'.nip.io';
		}
		elsif ($p_service eq 'sonaqrqube') {
			$v_domain_name = 'gitlab.iiidevops.'.$sonarqube_ip.'.nip.io';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = 'gitlab.iiidevops.'.$iiidevops_ip.'.nip.io';
		}
	}
	elsif (lc($deploy_mode) eq 'xip.io') {
		if ($p_service eq 'gitlab') {
			$v_domain_name = 'gitlab.iiidevops.'.$gitlab_ip.'.xip.io';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = 'gitlab.iiidevops.'.$redmine_ip.'.xip.io';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = 'gitlab.iiidevops.'.$harbor_ip.'.xip.io';
		}
		elsif ($p_service eq 'sonaqrqube') {
			$v_domain_name = 'gitlab.iiidevops.'.$sonarqube_ip.'.xip.io';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = 'gitlab.iiidevops.'.$iiidevops_ip.'.xip.io';
		}
	}
	else {
		# IP(Default)
		if ($p_service eq 'gitlab') {
			$v_domain_name = $gitlab_ip.':32080';
		}
		elsif ($p_service eq 'redmine') {
			$v_domain_name = $redmine_ip.':32748';
		}
		elsif ($p_service eq 'harbor') {
			$v_domain_name = $harbor_ip.':32443';
		}
		elsif ($p_service eq 'sonaqrqube') {
			$v_domain_name = $sonarqube_ip.':31910';
		}
		elsif ($p_service eq 'iiidevops') {
			$v_domain_name = $iiidevops_ip.':30775';
		}
	}
	
	return($v_domain_name);
}

# $logfile
sub log_print {
	my ($p_msg) = @_;

    print "$p_msg";
	
	open(FH, '>>', $logfile) or die $!;
	print FH $p_msg;
	close(FH);	

    return;
}

1;