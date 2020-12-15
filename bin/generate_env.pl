#!/usr/bin/perl
# Generate iiidevops env information script
#
use Socket;
use Sys::Hostname;
use FindBin qw($Bin);

$p_config = "$Bin/../env.pl";
$p_config_tmpl = $p_config.".tmpl";
if (!-e $p_config_tmpl) {
	print("The template file [$p_config_tmpl] does not exist!\n");
	exit;
}
$ans_tmpl = <<END;
# generate_env_answer
\$vm1_ip = '{{vm1_ip}}';
\$vm2_ip = '{{vm2_ip}}';
\$ask_gitlab_root_password = '{{ask_gitlab_root_password}}';
\$ask_gitlab_private_token = '{{ask_gitlab_private_token}}';
\$ask_rancher_admin_password = '{{ask_rancher_admin_password}}';
\$ask_redmine_admin_password = '{{ask_redmine_admin_password}}';
\$ask_redmine_api_key = '{{ask_redmine_api_key}}';
\$checkmarx_origin = '{{checkmarx_origin}}';
\$checkmarx_username = '{{checkmarx_username}}';
\$checkmarx_password = '{{checkmarx_password}}';
\$checkmarx_secret = '{{checkmarx_secret}}';

END
$p_config_tmpl_ans = $p_config.".ans";
if (-e $p_config_tmpl_ans) {
	require($p_config_tmpl_ans);
}

# 0. get host IP
$host = hostname();
$host_ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));

# 1. Set $vm1_ip
$vm1_ip = (defined($vm1_ip) && $vm1_ip ne '')?$vm1_ip:$host_ip;
$question = "Q1. Do you want to set [$vm1_ip] as the URL of the main service?(GitLab, Harbor...)? (Y/n)";
$Y_N = prompt_for_input($question);
while (lc($Y_N) eq 'n') {	
	$question = "Q1. Please enter the IP or domain name of the main service?(GitLab, Harbor...):";
	$vm1_ip = prompt_for_input($question, $vm1_ip);
	$Y_N = ($vm1_ip eq '')?'n':'Y';
}
$answer = "A1. Set [$vm1_ip] for the main service";
print ("$answer\n\n");
$ans_tmpl =~ s/{{vm1_ip}}/$vm1_ip/;
write_ans();

# 2. Set $vm2_ip
$vm2_ip = (defined($vm2_ip) && $vm2_ip ne '')?$vm2_ip:$host_ip;
$question = "Q2. Please enter the IP or domain name of the application service?(Redmine, Sonarqube...):($vm2_ip)";
$ans_ip = prompt_for_input($question);
$vm2_ip = ($ans_ip ne '')?$ans_ip:$vm2_ip;
$answer = "A2. Set [$vm2_ip] for the application service";
print ("$answer\n\n");
$ans_tmpl =~ s/{{vm2_ip}}/$vm2_ip/;
write_ans();

# 3. set GitLab root password
#\$ask_gitlab_root_password = '{{ask_gitlab_root_password}}';
$password1 = (defined($ask_gitlab_root_password) && $ask_gitlab_root_password ne '')?$ask_gitlab_root_password:'';
if ($password1 ne '') {
	$question = "Q3. Do you want to change GitlLab root password?(y/N)";
	$answer = "A3. Skip Set GitLab root password!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q3. Please enter the GitLab root password:";
	$password1 = prompt_for_password($question);
	$question = "Q3. Please re-enter the GitLab root password:";
	$password2 = prompt_for_password($question);
	$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
	if ($isAsk) {
		print("A3. The password is not the same, please re-enter!\n");
	}
	else {
		$answer = "A3. Set GitLab root password OK!";
	}
}
$ask_gitlab_root_password = $password1;
print ("$answer\n\n");
$ans_tmpl =~ s/{{ask_gitlab_root_password}}/$ask_gitlab_root_password/;
write_ans();


# 4. set GitLab Token
#\$ask_gitlab_private_token = '{{ask_gitlab_private_token}}';
$ask_gitlab_private_token = (defined($ask_gitlab_private_token) && $ask_gitlab_private_token ne '')?$ask_gitlab_private_token:'';
if ($ask_gitlab_private_token ne '') {
	$question = "Q4. Do you want to change GitlLab Token?(y/N)";
	$answer = "A4. Skip Set GitLab Token!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q4. Please enter the GitLab Token:";
	$ask_gitlab_private_token = prompt_for_input($question);
	$isAsk = ($ask_gitlab_private_token eq '');
	if ($isAsk) {
		print("A4. The Token is empty, please re-enter!\n");
	}
	else {
		$answer = "A4. Set GitLab Token OK!";
	}
}
print ("$answer\n\n");
$ans_tmpl =~ s/{{ask_gitlab_private_token}}/$ask_gitlab_private_token/;
write_ans();

# 5. set Rancher admin password
#\$ask_rancher_admin_password = '{{ask_rancher_admin_password}}';
$password1 = (defined($ask_rancher_admin_password) && $ask_rancher_admin_password ne '')?$ask_rancher_admin_password:'';
if ($password1 ne '') {
	$question = "Q5. Do you want to change Rancher admin password?(y/N)";
	$answer = "A5. Skip Set Rancher admin password!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q5. Please enter the Rancher admin password:";
	$password1 = prompt_for_password($question);
	$question = "Q5. Please re-enter the Rancher admin password:";
	$password2 = prompt_for_password($question);
	$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
	if ($isAsk) {
		print("A5. The password is not the same, please re-enter!\n");
	}
	else {
		$answer = "A5. Set Rancher admin password OK!";
	}
}
$ask_rancher_admin_password = $password1;
print ("$answer\n\n");
$ans_tmpl =~ s/{{ask_rancher_admin_password}}/$ask_rancher_admin_password/;
write_ans();

# 6. set Redmine admin password
#\$ask_redmine_admin_password = '{{ask_redmine_admin_password}}';
$password1 = (defined($ask_redmine_admin_password) && $ask_redmine_admin_password ne '')?$ask_redmine_admin_password:'';
if ($password1 ne '') {
	$question = "Q6. Do you want to change Redmine admin password?(y/N)";
	$answer = "A6. Skip Set Redmine admin password!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q6. Please enter the Redmine admin password:";
	$password1 = prompt_for_password($question);
	$question = "Q6. Please re-enter the Redmine admin password:";
	$password2 = prompt_for_password($question);
	$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
	if ($isAsk) {
		print("A6. The password is not the same, please re-enter!\n");
	}
	else {
		$answer = "A6. Set Redmine admin password OK!";
	}
}
$ask_redmine_admin_password = $password1;
print ("$answer\n\n");
$ans_tmpl =~ s/{{ask_redmine_admin_password}}/$ask_redmine_admin_password/;
write_ans();

# 7. set Redmine API key
#\$ask_redmine_api_key = '{{ask_redmine_api_key}}';
$ask_redmine_api_key = (defined($ask_redmine_api_key) && $ask_redmine_api_key ne '')?$ask_redmine_api_key:'';
if ($ask_redmine_api_key ne '') {
	$question = "Q7. Do you want to change Redmine API key?(y/N)";
	$answer = "A7. Skip Set Redmine API key!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q7. Please enter the Redmine API key:";
	$ask_redmine_api_key = prompt_for_input($question);
	$isAsk = ($ask_redmine_api_key eq '');
	if ($isAsk) {
		print("A7. The API key is empty, please re-enter!\n");
	}
	else {
		$answer = "A7. Set Redmine API key OK!";
	}
}
print ("$answer\n\n");
$ans_tmpl =~ s/{{ask_redmine_api_key}}/$ask_redmine_api_key/;
write_ans();

#------------------------------
# checkmarx setting(Option)
#------------------------------
# 8. \$checkmarx_origin = '{{checkmarx_origin}}';
$checkmarx_origin = (defined($checkmarx_origin) && $checkmarx_origin ne '')?$checkmarx_origin:'';
if ($checkmarx_origin ne '') {
	$question = "Q8. Do you want to change Checkmarx origin?(y/N)";
	$answer = "A8. Skip Set Checkmarx origin!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q8. Please enter the Checkmarx origin:";
	$checkmarx_origin = prompt_for_input($question);
	$isAsk = ($checkmarx_origin eq '');
	if ($isAsk) {
		print("A8. The Checkmarx origin is empty, please re-enter!\n");
	}
	else {
		$answer = "A8. Set Checkmarx origin OK!";
	}
}
print ("$answer\n\n");
$ans_tmpl =~ s/{{checkmarx_origin}}/$checkmarx_origin/;
write_ans();

# 9. \$checkmarx_username = '{{checkmarx_username}}';
$checkmarx_username = (defined($checkmarx_username) && $checkmarx_username ne '')?$checkmarx_username:'';
if ($checkmarx_username ne '') {
	$question = "Q9. Do you want to change Checkmarx username?(y/N)";
	$answer = "A9. Skip Set Checkmarx username!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q9. Please enter the Checkmarx username:";
	$checkmarx_username = prompt_for_input($question);
	$isAsk = ($checkmarx_username eq '');
	if ($isAsk) {
		print("A9. The Checkmarx username is empty, please re-enter!\n");
	}
	else {
		$answer = "A9. Set Checkmarx username OK!";
	}
}
print ("$answer\n\n");
$ans_tmpl =~ s/{{checkmarx_username}}/$checkmarx_username/;
write_ans();

# 10. \$checkmarx_password = '{{checkmarx_password}}';
$password1 = (defined($checkmarx_password) && $checkmarx_password ne '')?$checkmarx_password:'';
if ($password1 ne '') {
	$question = "Q10. Do you want to change Checkmarx password?(y/N)";
	$answer = "A10. Skip Set Checkmarx password!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q10. Please enter the Checkmarx password:";
	$password1 = prompt_for_password($question);
	$question = "Q10. Please re-enter the Checkmarx password:";
	$password2 = prompt_for_password($question);
	$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
	if ($isAsk) {
		print("A10. The password is not the same, please re-enter!\n");
	}
	else {
		$answer = "A10. Set Checkmarx password OK!";
	}
}
$checkmarx_password = $password1;
print ("$answer\n\n");
$ans_tmpl =~ s/{{checkmarx_password}}/$checkmarx_password/;
write_ans();

# 11. \$checkmarx_secret = '{{checkmarx_secret}}';
$checkmarx_secret = (defined($checkmarx_secret) && $checkmarx_secret ne '')?$checkmarx_secret:'';
if ($checkmarx_secret ne '') {
	$question = "Q11. Do you want to change Checkmarx secret?(y/N)";
	$answer = "A11. Skip Set Checkmarx secret!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk=1;
}
while ($isAsk) {
	$question = "Q11. Please enter the Checkmarx secret:";
	$checkmarx_secret = prompt_for_input($question);
	$isAsk = ($checkmarx_secret eq '');
	if ($isAsk) {
		print("A11. The Checkmarx secret is empty, please re-enter!\n");
	}
	else {
		$answer = "A11. Set Checkmarx secret OK!";
	}
}
print ("$answer\n\n");
$ans_tmpl =~ s/{{checkmarx_secret}}/$checkmarx_secret/;
write_ans();

exit;


sub write_ans {

	open(FH, '>', $p_config_tmpl_ans) or die $!;
	print FH $ans_tmpl;
	close(FH);
	
	return;	
}

# Ref - http://www.tizag.com/perlT/perluserinput.php
sub prompt_for_input {
	my ($p_question) = @_;
    print "$p_question";
	my $answer = <>;
    $answer =~ s/\R\z//;

    return $answer;
}

# Ref - https://stackoverflow.com/questions/39801195/how-can-perl-prompt-for-a-password-without-showing-it-in-the-terminal
sub prompt_for_password {
	my ($p_question) = @_;

	require Term::ReadKey;
    # Tell the terminal not to show the typed chars
    Term::ReadKey::ReadMode('noecho');
    print "$p_question";
    my $password = Term::ReadKey::ReadLine(0);
    # Rest the terminal to what it was previously doing
    Term::ReadKey::ReadMode('restore');
    print "\n";

    # get rid of that pesky line ending (and works on Windows)
    $password =~ s/\R\z//;

    return $password;
}