#!/usr/bin/perl
#
#------------------------------
# domain name setting(services)
#------------------------------

# 2.3a \$gitlab_domain_name = '{{ask_gitlab_domain_name}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_gitlab_domain_name') {
	if (!defined($ARGV[1])) {
		$ask_gitlab_domain_name = (defined($ask_gitlab_domain_name) && $ask_gitlab_domain_name ne '{{ask_gitlab_domain_name}}' && $ask_gitlab_domain_name ne '')?$ask_gitlab_domain_name:'';
		if ($ask_gitlab_domain_name ne '') {
			$question = "Q2.3a Do you want to change Gitlab domain name:($ask_gitlab_domain_name)?(y/N)";
			$answer = "A2.3a Skip Set Gitlab domain name!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q2.3a Please enter the Gitlab domain name:";
			$ask_gitlab_domain_name = prompt_for_input($question);
			$isAsk = ($ask_gitlab_domain_name eq '');
			if ($isAsk) {
				print("A2.3a The Gitlab domain name is empty, please re-enter!\n");
			}
			else {
				$answer = "A2.3a Set Gitlab domain name OK!";
			}
		}
	}
	else {
		$ask_gitlab_domain_name = $ARGV[1];
		$answer = "A2.3a Set Gitlab domain name OK!";
	}
	print ("$answer\n\n");
	if ($ask_gitlab_domain_name ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_gitlab_domain_name;
			require($p_config_tmpl_ans);
			$ask_gitlab_domain_name=$tmp;
		}
		write_ans();
	}
}

# 2.3b \$harbor_domain_name = '{{ask_harbor_domain_name}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_harbor_domain_name') {
	if (!defined($ARGV[1])) {
		$ask_harbor_domain_name = (defined($ask_harbor_domain_name) && $ask_harbor_domain_name ne '{{ask_harbor_domain_name}}' && $ask_harbor_domain_name ne '')?$ask_harbor_domain_name:'';
		if ($ask_harbor_domain_name ne '') {
			$question = "Q2.3b Do you want to change Harbor domain name:($ask_harbor_domain_name)?(y/N)";
			$answer = "A2.3b Skip Set Harbor domain name!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q2.3b Please enter the Harbor domain name:";
			$ask_harbor_domain_name = prompt_for_input($question);
			$isAsk = ($ask_harbor_domain_name eq '');
			if ($isAsk) {
				print("A2.3b The Harbor domain name is empty, please re-enter!\n");
			}
			else {
				$answer = "A2.3b Set Harbor domain name OK!";
			}
		}
	}
	else {
		$ask_harbor_domain_name = $ARGV[1];
		$answer = "A2.3b Set Harbor domain name OK!";
	}
	print ("$answer\n\n");
	if ($ask_harbor_domain_name ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_harbor_domain_name;
			require($p_config_tmpl_ans);
			$ask_harbor_domain_name=$tmp;
		}
		write_ans();
	}
}

# 2.3c \$redmine_domain_name = '{{ask_redmine_domain_name}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_redmine_domain_name') {
	if (!defined($ARGV[1])) {
		$ask_redmine_domain_name = (defined($ask_redmine_domain_name) && $ask_redmine_domain_name ne '{{ask_redmine_domain_name}}' && $ask_redmine_domain_name ne '')?$ask_redmine_domain_name:'';
		if ($ask_redmine_domain_name ne '') {
			$question = "Q2.3c Do you want to change Redmine domain name:($ask_redmine_domain_name)?(y/N)";
			$answer = "A2.3c Skip Set Redmine domain name!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q2.3c Please enter the Redmine domain name:";
			$ask_redmine_domain_name = prompt_for_input($question);
			$isAsk = ($ask_redmine_domain_name eq '');
			if ($isAsk) {
				print("A2.3c The Redmine domain name is empty, please re-enter!\n");
			}
			else {
				$answer = "A2.3c Set Redmine domain name OK!";
			}
		}
	}
	else {
		$ask_redmine_domain_name = $ARGV[1];
		$answer = "A2.3c Set Redmine domain name OK!";
	}
	print ("$answer\n\n");
	if ($ask_redmine_domain_name ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_redmine_domain_name;
			require($p_config_tmpl_ans);
			$ask_redmine_domain_name=$tmp;
		}
		write_ans();
	}
}

# 2.3d \$sonarqube_domain_name = '{{ask_sonarqube_domain_name}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_sonarqube_domain_name') {
	if (!defined($ARGV[1])) {
		$ask_sonarqube_domain_name = (defined($ask_sonarqube_domain_name) && $ask_sonarqube_domain_name ne '{{ask_sonarqube_domain_name}}' && $ask_sonarqube_domain_name ne '')?$ask_sonarqube_domain_name:'';
		if ($ask_sonarqube_domain_name ne '') {
			$question = "Q2.3d Do you want to change Sonarqube domain name:($ask_sonarqube_domain_name)?(y/N)";
			$answer = "A2.3d Skip Set Sonarqube domain name!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q2.3d Please enter the Sonarqube domain name:";
			$ask_sonarqube_domain_name = prompt_for_input($question);
			$isAsk = ($ask_sonarqube_domain_name eq '');
			if ($isAsk) {
				print("A2.3d The Sonarqube domain name is empty, please re-enter!\n");
			}
			else {
				$answer = "A2.3d Set Sonarqube domain name OK!";
			}
		}
	}
	else {
		$ask_sonarqube_domain_name = $ARGV[1];
		$answer = "A2.3d Set Sonarqube domain name OK!";
	}
	print ("$answer\n\n");
	if ($ask_sonarqube_domain_name ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_sonarqube_domain_name;
			require($p_config_tmpl_ans);
			$ask_sonarqube_domain_name=$tmp;
		}
		write_ans();
	}
}

# 2.3e \$iiidevops_domain_name = '{{ask_iiidevops_domain_name}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_iiidevops_domain_name') {
	if (!defined($ARGV[1])) {
		$ask_iiidevops_domain_name = (defined($ask_iiidevops_domain_name) && $ask_iiidevops_domain_name ne '{{ask_iiidevops_domain_name}}' && $ask_iiidevops_domain_name ne '')?$ask_iiidevops_domain_name:'';
		if ($ask_iiidevops_domain_name ne '') {
			$question = "Q2.3e Do you want to change III DevOps domain name:($ask_iiidevops_domain_name)?(y/N)";
			$answer = "A2.3e Skip Set III DevOps domain name!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q2.3e Please enter the III DevOps domain name:";
			$ask_iiidevops_domain_name = prompt_for_input($question);
			$isAsk = ($ask_iiidevops_domain_name eq '');
			if ($isAsk) {
				print("A2.3e The III DevOps domain name is empty, please re-enter!\n");
			}
			else {
				$answer = "A2.3e Set III DevOps domain name OK!";
			}
		}
	}
	else {
		$ask_iiidevops_domain_name = $ARGV[1];
		$answer = "A2.3e Set III DevOps domain name OK!";
	}
	print ("$answer\n\n");
	if ($ask_iiidevops_domain_name ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_iiidevops_domain_name;
			require($p_config_tmpl_ans);
			$ask_iiidevops_domain_name=$tmp;
		}
		write_ans();
	}
}

1;