#!/usr/bin/perl
#
#------------------------------
# checkmarx setting(Option)
#------------------------------

# 11a. \$ask_checkmarx_origin = '{{ask_checkmarx_origin}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_origin') {
	if (!defined($ARGV[1])) {
		$ask_checkmarx_origin = (defined($ask_checkmarx_origin) && $ask_checkmarx_origin ne '{{checkmarx_origin}}' && $ask_checkmarx_origin ne '')?$ask_checkmarx_origin:'';
		if ($ask_checkmarx_origin ne '') {
			$question = "Q11a. Do you want to change Checkmarx origin?(y/N)";
			$answer = "A11a. Skip Set Checkmarx origin!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q11a. Please enter the Checkmarx origin:";
			$ask_checkmarx_origin = prompt_for_input($question);
			$isAsk = ($ask_checkmarx_origin eq '');
			if ($isAsk) {
				print("A11a. The Checkmarx origin is empty, please re-enter!\n");
			}
			else {
				$answer = "A11a. Set Checkmarx origin OK!";
			}
		}
	}
	else {
		$ask_checkmarx_origin = $ARGV[1];
		$answer = "A11a. Set Checkmarx origin OK!";
	}
	print ("$answer\n\n");
	if ($ask_checkmarx_origin ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_checkmarx_origin;
			require($p_config_tmpl_ans);
			$ask_checkmarx_origin=$tmp;
		}
		write_ans();
	}
}

# 11b. \$ask_checkmarx_username = '{{ask_checkmarx_username}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_username') {
	if (!defined($ARGV[1])) {
		$ask_checkmarx_username = (defined($ask_checkmarx_username) && $ask_checkmarx_username ne '{{checkmarx_username}}' && $ask_checkmarx_username ne '')?$ask_checkmarx_username:'';
		if ($ask_checkmarx_username ne '') {
			$question = "Q11b. Do you want to change Checkmarx username?(y/N)";
			$answer = "A11b. Skip Set Checkmarx username!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q11b. Please enter the Checkmarx username:";
			$ask_checkmarx_username = prompt_for_input($question);
			$isAsk = ($ask_checkmarx_username eq '');
			if ($isAsk) {
				print("A11b. The Checkmarx username is empty, please re-enter!\n");
			}
			else {
				$answer = "A11b. Set Checkmarx username OK!";
			}
		}
	}
	else {
		$ask_checkmarx_username = $ARGV[1];
		$answer = "A11b. Set Checkmarx username OK!";
	}
	print ("$answer\n\n");
	if ($ask_checkmarx_username ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_checkmarx_username;
			require($p_config_tmpl_ans);
			$ask_checkmarx_username=$tmp;
		}
		write_ans();
	}
}

# 11c. \$ask_checkmarx_password = '{{ask_checkmarx_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_checkmarx_password) && $ask_checkmarx_password ne '{{checkmarx_password}}' && $ask_checkmarx_password ne '')?$ask_checkmarx_password:'';
		if ($password1 ne '') {
			$question = "Q11c. Do you want to change Checkmarx password?(y/N)";
			$answer = "A11c. Skip Set Checkmarx password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q11c. Please enter the Checkmarx password:";
			$password1 = prompt_for_password($question);
			$question = "Q11c. Please re-enter the Checkmarx password:";
			$password2 = prompt_for_password($question);
			$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			if ($isAsk) {
				print("A11c. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A11c. Set Checkmarx password OK!";
			}
		}
		$ask_checkmarx_password = $password1;
	}
	else {
		$ask_checkmarx_password = $ARGV[1];
		$answer = "A11c. Set Checkmarx password OK!";
	}
	print ("$answer\n\n");
	if ($ask_checkmarx_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_checkmarx_password;
			require($p_config_tmpl_ans);
			$ask_checkmarx_password=$tmp;
		}
		write_ans();
	}
}

# 11d. \$ask_checkmarx_secret = '{{ask_checkmarx_secret}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_secret') {
	if (!defined($ARGV[1])) {
		$ask_checkmarx_secret = (defined($ask_checkmarx_secret) && $ask_checkmarx_secret ne '{{checkmarx_secret}}' && $ask_checkmarx_secret ne '')?$ask_checkmarx_secret:'';
		if ($ask_checkmarx_secret ne '') {
			$question = "Q11d. Do you want to change Checkmarx secret?(y/N)";
			$answer = "A11d. Skip Set Checkmarx secret!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q11d. Please enter the Checkmarx secret:";
			$ask_checkmarx_secret = prompt_for_input($question);
			$isAsk = ($ask_checkmarx_secret eq '');
			if ($isAsk) {
				print("A11d. The Checkmarx secret is empty, please re-enter!\n");
			}
			else {
				$answer = "A11d. Set Checkmarx secret OK!";
			}
		}
	}
	else {
		$ask_checkmarx_secret = $ARGV[1];
		$answer = "A11d. Set Checkmarx secret OK!";
	}
	print ("$answer\n\n");
	if ($ask_checkmarx_secret ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_checkmarx_secret;
			require($p_config_tmpl_ans);
			$ask_checkmarx_secret=$tmp;
		}
		write_ans();
	}
}

1;