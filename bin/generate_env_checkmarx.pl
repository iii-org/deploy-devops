#!/usr/bin/perl
#
#------------------------------
# checkmarx setting(Option)
#------------------------------

# 11a. \$checkmarx_origin = '{{checkmarx_origin}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_origin') {
	if (!defined($ARGV[1])) {
		$checkmarx_origin = (defined($checkmarx_origin) && $checkmarx_origin ne '{{checkmarx_origin}}' && $checkmarx_origin ne '')?$checkmarx_origin:'';
		if ($checkmarx_origin ne '') {
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
			$checkmarx_origin = prompt_for_input($question);
			$isAsk = ($checkmarx_origin eq '');
			if ($isAsk) {
				print("A11a. The Checkmarx origin is empty, please re-enter!\n");
			}
			else {
				$answer = "A11a. Set Checkmarx origin OK!";
			}
		}
	}
	else {
		$checkmarx_origin = $ARGV[1];
		$answer = "A11a. Set Checkmarx origin OK!";
	}
	print ("$answer\n\n");
	write_ans();
}

# 11b. \$checkmarx_username = '{{checkmarx_username}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_username') {
	if (!defined($ARGV[1])) {
		$checkmarx_username = (defined($checkmarx_username) && $checkmarx_username ne '{{checkmarx_username}}' && $checkmarx_username ne '')?$checkmarx_username:'';
		if ($checkmarx_username ne '') {
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
			$checkmarx_username = prompt_for_input($question);
			$isAsk = ($checkmarx_username eq '');
			if ($isAsk) {
				print("A11b. The Checkmarx username is empty, please re-enter!\n");
			}
			else {
				$answer = "A11b. Set Checkmarx username OK!";
			}
		}
	}
	else {
		$checkmarx_username = $ARGV[1];
		$answer = "A11b. Set Checkmarx username OK!";
	}
	print ("$answer\n\n");
	write_ans();
}

# 11c. \$checkmarx_password = '{{checkmarx_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($checkmarx_password) && $checkmarx_password ne '{{checkmarx_password}}' && $checkmarx_password ne '')?$checkmarx_password:'';
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
		$checkmarx_password = $password1;
	}
	else {
		$checkmarx_password = $ARGV[1];
		$answer = "A11c. Set Checkmarx password OK!";
	}
	print ("$answer\n\n");
	write_ans();
}

# 11d. \$checkmarx_secret = '{{checkmarx_secret}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'checkmarx_secret') {
	if (!defined($ARGV[1])) {
		$checkmarx_secret = (defined($checkmarx_secret) && $checkmarx_secret ne '{{checkmarx_secret}}' && $checkmarx_secret ne '')?$checkmarx_secret:'';
		if ($checkmarx_secret ne '') {
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
			$checkmarx_secret = prompt_for_input($question);
			$isAsk = ($checkmarx_secret eq '');
			if ($isAsk) {
				print("A11d. The Checkmarx secret is empty, please re-enter!\n");
			}
			else {
				$answer = "A11d. Set Checkmarx secret OK!";
			}
		}
	}
	else {
		$checkmarx_secret = $ARGV[1];
		$answer = "A11d. Set Checkmarx secret OK!";
	}
	print ("$answer\n\n");
	write_ans();
}
