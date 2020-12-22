#!/usr/bin/perl
#
#------------------------------
# iiidevops settings(Core)
#------------------------------
#
# 9. set III-DevOps settings(Core)
# 9a. \$ask_admin_init_login = '{{ask_admin_init_login}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_admin_init_login') {
	if (!defined($ARGV[1])) {
		$ask_admin_init_login = (defined($ask_admin_init_login) && $ask_admin_init_login ne '{{ask_admin_init_login}}' && $ask_admin_init_login ne '')?$ask_admin_init_login:'';
		if ($ask_admin_init_login ne '') {
			$question = "Q9a. Do you want to change III-DevOps first user username?(y/N)";
			$answer = "A9a. Skip Set III-DevOps first user username!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q9a. Please enter the III-DevOps first user username:";
			$ask_admin_init_login = prompt_for_input($question);
			$isAsk = ($ask_admin_init_login eq '' || $ask_admin_init_login eq 'admin');
			if ($isAsk) {
				print("A9a. The III-DevOps first user username is 'admin' or empty, please re-enter!\n");
			}
			else {
				$answer = "A9a. Set III-DevOps first user username OK!";
			}
		}
	}
	else {
		$ask_admin_init_login = $ARGV[1];
		$answer = "A9a. Set III-DevOps first user username OK!";
	}
	print ("$answer\n\n");
	write_ans();
}

# 9b. \$ask_admin_init_email = '{{ask_admin_init_email}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_admin_init_email') {
	if (!defined($ARGV[1])) {
		$ask_admin_init_email = (defined($ask_admin_init_email) && $ask_admin_init_email ne '{{ask_admin_init_email}}' && $ask_admin_init_email ne '')?$ask_admin_init_email:'';
		if ($ask_admin_init_email ne '') {
			$question = "Q9b. Do you want to change III-DevOps first user E-Mail?(y/N)";
			$answer = "A9b. Skip Set III-DevOps first user E-Mail!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q9b. Please enter the III-DevOps first user E-Mail:";
			$ask_admin_init_email = prompt_for_input($question);
			$isAsk = ($ask_admin_init_email eq '');
			if ($isAsk) {
				print("A9b. The III-DevOps first user E-Mail is empty, please re-enter!\n");
			}
			else {
				$answer = "A9b. Set III-DevOps first user E-Mail OK!";
			}
		}
	}
	else {
		$ask_admin_init_email = $ARGV[1];
		$answer = "A9b. Set III-DevOps first user E-Mail OK!";
	}
	print ("$answer\n\n");
	write_ans();
}

# 9c. \$ask_admin_init_password = '{{ask_admin_init_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_admin_init_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_admin_init_password) && $ask_admin_init_password ne '{{ask_admin_init_password}}' && $ask_admin_init_password ne '')?$ask_admin_init_password:'';
		if ($password1 ne '') {
			$question = "Q9c. Do you want to change III-DevOps first user password?(y/N)";
			$answer = "A9c. Skip Set III-DevOps first user password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q9c. Please enter the III-DevOps first user password:";
			$password1 = prompt_for_password($question);
			$question = "Q9c. Please re-enter the III-DevOps first user password:";
			$password2 = prompt_for_password($question);
			$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			if ($isAsk) {
				print("A9c. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A9c. Set III-DevOps first user password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A9c. Set III-DevOps first user password OK!";
	}
	$ask_admin_init_password = $password1;
	print ("$answer\n\n");
	write_ans();
}

1;