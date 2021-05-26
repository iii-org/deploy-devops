#!/usr/bin/perl
#
#------------------------------
# WebInspect settings(Option)
#------------------------------

# 12. set WebInspect settings(Option)
# 12a. \$ask_webinspect_base_url = '{{ask_webinspect_base_url}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'webinspect_base_url') {
	if (!defined($ARGV[1])) {
		$ask_webinspect_base_url = (defined($ask_webinspect_base_url) && $ask_webinspect_base_url ne '{{webinspect_base_url}}' && $ask_webinspect_base_url ne '')?$ask_webinspect_base_url:'';
		if ($ask_webinspect_base_url ne '') {
			$question = "Q12a. Do you want to change WebInspect URL?(y/N)";
			$answer = "A12a. Skip Set WebInspect URL!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q12a. Please enter the WebInspect URL:";
			$ask_webinspect_base_url = prompt_for_input($question);
			$isAsk = ($ask_webinspect_base_url eq '');
			if ($isAsk) {
				print("A12a. The WebInspect URL is empty, please re-enter!\n");
			}
			else {
				$answer = "A12a. Set WebInspect URL OK!";
			}
		}
	}
	else {
		$ask_webinspect_base_url = $ARGV[1];
		$answer = "A12a. Set WebInspect URL OK!";
	}
	print ("$answer\n\n");
	if ($ask_webinspect_base_url ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_webinspect_base_url;
			require($p_config_tmpl_ans);
			$ask_webinspect_base_url=$tmp;
		}
		write_ans();
	}
}

# 12b. \$ask_webinspect_type = '{{ask_webinspect_type}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'webinspect_type') {
	if (!defined($ARGV[1])) {
		$ask_webinspect_type = (defined($ask_webinspect_type) && $ask_webinspect_type ne '{{webinspect_type}}' && $ask_webinspect_type ne '')?$ask_webinspect_type:'';
		if ($ask_webinspect_type ne '') {
			$question = "Q12b. Do you want to change WebInspect Type?(y/N)";
			$answer = "A12b. Skip Set WebInspect Type!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q12b. Please enter the WebInspect Type(If you use WIE type 'WIE', otherwise omit it):";
			$ask_webinspect_type = uc(prompt_for_input($question));
			$isAsk = ($ask_webinspect_type ne '' && $ask_webinspect_type ne 'WIE');
			if ($isAsk) {
				print("A12b. The WebInspect Type must 'WIE' or empty, please re-enter!\n");
			}
			else {
				$answer = "A12b. Set WebInspect Type OK!";
			}
		}
	}
	else {
		$ask_webinspect_type = $ARGV[1];
		$answer = "A12b. Set WebInspect Type OK!";
	}
	print ("$answer\n\n");
	#if ($ask_webinspect_type ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_webinspect_type;
			require($p_config_tmpl_ans);
			$ask_webinspect_type=$tmp;
		}
		write_ans();
	#}
}

# 12c. \$ask_webinspect_username = '{{ask_webinspect_username}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'webinspect_username') {
	if (!defined($ARGV[1])) {
		$ask_webinspect_username = (defined($ask_webinspect_username) && $ask_webinspect_username ne '{{webinspect_username}}' && $ask_webinspect_username ne '')?$ask_webinspect_username:'';
		if ($ask_webinspect_username ne '') {
			$question = "Q12c. Do you want to change WebInspect username?(y/N)";
			$answer = "A12c. Skip Set WebInspect username!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q12c. Please enter the WebInspect username:";
			$ask_webinspect_username = prompt_for_input($question);
			$isAsk = ($ask_webinspect_username eq '');
			if ($isAsk) {
				print("A12c. The WebInspect username is empty, please re-enter!\n");
			}
			else {
				$answer = "A12c. Set WebInspect username OK!";
			}
		}
	}
	else {
		$ask_webinspect_username = $ARGV[1];
		$answer = "A12c. Set WebInspect username OK!";
	}
	print ("$answer\n\n");
	if ($ask_webinspect_username ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_webinspect_username;
			require($p_config_tmpl_ans);
			$ask_webinspect_username=$tmp;
		}
		write_ans();
	}
}

# 12d. \$ask_webinspect_password = '{{ask_webinspect_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'webinspect_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_webinspect_password) && $ask_webinspect_password ne '{{webinspect_password}}' && $ask_webinspect_password ne '')?$ask_webinspect_password:'';
		if ($password1 ne '') {
			$question = "Q12d. Do you want to change WebInspect password?(y/N)";
			$answer = "A12d. Skip Set WebInspect password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q12d. Please enter the WebInspect password:";
			$password1 = prompt_for_password($question);
			$question = "Q12d. Please re-enter the WebInspect password:";
			$password2 = prompt_for_password($question);
			$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			if ($isAsk) {
				print("A12d. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A12d. Set WebInspect password OK!";
			}
		}
		$ask_webinspect_password = $password1;
	}
	else {
		$ask_webinspect_password = $ARGV[1];
		$answer = "A12d. Set WebInspect password OK!";
	}
	print ("$answer\n\n");
	if ($ask_webinspect_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_webinspect_password;
			require($p_config_tmpl_ans);
			$ask_webinspect_password=$tmp;
		}
		write_ans();
	}
}

1;