#!/usr/bin/perl
# Generate iiidevops env information script
#
use Socket;
use Sys::Hostname;
use FindBin qw($Bin);

$p_config = "$Bin/../env.pl";
$p_config_bak = $p_config.".bak";
$p_config_tmpl = $p_config.".tmpl";
if (!-e $p_config_tmpl) {
	print("The template file [$p_config_tmpl] does not exist!\n");
	exit;
}

$nfs_dir = defined($nfs_dir)?$nfs_dir:'/iiidevopsNFS';

if (-e "$nfs_dir/deploy-config/env.pl") {
	$cmd_msg = `rm -f $p_config; ln -s $nfs_dir/deploy-config/env.pl $p_config`; 
}
if (-e "$nfs_dir/deploy-config/env.pl.ans") {
	$cmd_msg = `rm -f $p_config.ans; ln -s $nfs_dir/deploy-config/env.pl.ans $p_config.ans`; 
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
\$ask_harbor_admin_password = '{{ask_harbor_admin_password}}';
\$ask_admin_init_login = '{{ask_admin_init_login}}';
\$ask_admin_init_email = '{{ask_admin_init_email}}';
\$ask_admin_init_password = '{{ask_admin_init_password}}';
\$checkmarx_origin = '{{checkmarx_origin}}';
\$checkmarx_username = '{{checkmarx_username}}';
\$checkmarx_password = '{{checkmarx_password}}';
\$checkmarx_secret = '{{checkmarx_secret}}';
\$webinspect_base_url = '{{webinspect_base_url}}';
\$auto_password = '{{auto_password}}';
\$random_key = '{{random_key}}';

1;
END
# No longer needed key

$p_config_tmpl_ans = $p_config.".ans";

# 0. get host IP
$host = hostname();
$host_ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));

# Set the specified key value
if (defined($ARGV[0])) {
	if (index($ans_tmpl, '{{'.$ARGV[0].'}}')<0) {
		print("The specified key: [$ARGV[0]] is unknown!\n");
		exit;
	}
}

# 1. Set $vm1_ip
if (!defined($ARGV[0]) || $ARGV[0] eq 'vm1_ip') {
	if (!defined($ARGV[1])) {
		$vm1_ip = (defined($vm1_ip) && $vm1_ip ne '{{vm1_ip}}' && $vm1_ip ne '')?$vm1_ip:$host_ip;
		$question = "Q1. Do you want to set VM1 IP [$vm1_ip] as the URL of the main services?(GitLab, Harbor...)? (Y/n)";
		$Y_N = prompt_for_input($question);
		while (lc($Y_N) eq 'n') {	
			$question = "Q1. Please enter the IP or domain name of the main services?(GitLab, Harbor...):";
			$vm1_ip = prompt_for_input($question, $vm1_ip);
			$Y_N = ($vm1_ip eq '')?'n':'Y';
		}
	}
	else {
		$vm1_ip = $ARGV[1];
	}
	$answer = "A1. Set [$vm1_ip] for the main services";
	print ("$answer\n\n");
	if ($vm1_ip ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$vm1_ip;
			require($p_config_tmpl_ans);
			$vm1_ip=$tmp;
		}
		write_ans();
	}
}

# 2. Set $vm2_ip
if (!defined($ARGV[0]) || $ARGV[0] eq 'vm2_ip') {
	if (!defined($ARGV[1])) {
		$vm2_ip = (defined($vm2_ip) && $vm2_ip ne '{{vm2_ip}}' && $vm2_ip ne '')?$vm2_ip:$host_ip;
		$question = "Q2. Please enter the VM2 IP or domain name of the application services?(Redmine, Sonarqube, iiidevops...):($vm2_ip)";
		$ans_ip = prompt_for_input($question);
		$vm2_ip = ($ans_ip ne '')?$ans_ip:$vm2_ip;
	}
	else {
		$vm2_ip = $ARGV[1];
	}
	$answer = "A2. Set [$vm2_ip] for the application services";
	print ("$answer\n\n");
	if ($vm2_ip ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$vm2_ip;
			require($p_config_tmpl_ans);
			$vm2_ip=$tmp;
		}
		write_ans();
	}
}

# 3. set GitLab root password
#\$ask_gitlab_root_password = '{{ask_gitlab_root_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_gitlab_root_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_gitlab_root_password) && $ask_gitlab_root_password ne '{{ask_gitlab_root_password}}' && $ask_gitlab_root_password ne '')?$ask_gitlab_root_password:'';
		if ($password1 ne '') {
			$question = "Q3. Do you want to change GitLab root password?(y/N)";
			$answer = "A3. Skip Set GitLab root password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');
		}	
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q3. Please enter the GitLab root password:(Must be 8-20 characters long with at least 1 uppercase, 1 lowercase and 1 number)";
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
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A3. Set GitLab root password OK!";
	}
	$ask_gitlab_root_password = $password1;
	print ("$answer\n\n");
	if ($ask_gitlab_root_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_gitlab_root_password;
			require($p_config_tmpl_ans);
			$ask_gitlab_root_password=$tmp;
		}
		write_ans();
	}
}

# Set same_passwd for another password 
$same_passwd = $ask_gitlab_root_password;


# 4. set GitLab Token
#\$ask_gitlab_private_token = '{{ask_gitlab_private_token}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_gitlab_private_token') {
	if (!defined($ARGV[1])) {
		$ask_gitlab_private_token = (defined($ask_gitlab_private_token) && $ask_gitlab_private_token ne '{{ask_gitlab_private_token}}' && $ask_gitlab_private_token ne '' && lc($ask_gitlab_private_token) ne 'skip')?$ask_gitlab_private_token:'';
		if ($ask_gitlab_private_token ne '') {
			$question = "Q4. Do you want to change GitLab Token?(y/N)";
			$answer = "A4. Skip Set GitLab Token!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q4. Please enter the GitLab Token:(If your GitLab has not been set up, please enter 'SKIP')";
			$ask_gitlab_private_token = prompt_for_input($question);
			$isAsk = ($ask_gitlab_private_token eq '');
			if ($isAsk) {
				print("A4. The Token is empty, please re-enter!\n");
			}
			else {
				$answer = "A4. Set GitLab Token OK!";
			}
		}
	}
	else {
		$ask_gitlab_private_token = $ARGV[1];
		$answer = "A4. Set GitLab Token OK!";
	}
	print ("$answer\n\n");
	if ($ask_gitlab_private_token ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_gitlab_private_token;
			require($p_config_tmpl_ans);
			$ask_gitlab_private_token=$tmp;
		}
		write_ans();
	}
}

# 5. set Rancher admin password
#\$ask_rancher_admin_password = '{{ask_rancher_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_rancher_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_rancher_admin_password) && $ask_rancher_admin_password ne '{{ask_rancher_admin_password}}' && $ask_rancher_admin_password ne '')?$ask_rancher_admin_password:'';
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
			$question = "Q5. Please enter the Rancher admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q5. Please re-enter the Rancher admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A5. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A5. Set Rancher admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A5. Set Rancher admin password OK!";
	}
	$ask_rancher_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_rancher_admin_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_rancher_admin_password;
			require($p_config_tmpl_ans);
			$ask_rancher_admin_password=$tmp;
		}
		write_ans();
	}
}

# 6. set Redmine admin password
#\$ask_redmine_admin_password = '{{ask_redmine_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_redmine_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_redmine_admin_password) && $ask_redmine_admin_password ne '{{ask_redmine_admin_password}}' && $ask_redmine_admin_password ne '')?$ask_redmine_admin_password:'';
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
			$question = "Q6. Please enter the Redmine admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q6. Please re-enter the Redmine admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A6. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A6. Set Redmine admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A6. Set Redmine admin password OK!";
	}
	$ask_redmine_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_redmine_admin_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_redmine_admin_password;
			require($p_config_tmpl_ans);
			$ask_redmine_admin_password=$tmp;
		}
		write_ans();
	}
}

# 7. set Redmine API key
#\$ask_redmine_api_key = '{{ask_redmine_api_key}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_redmine_api_key') {
	if (!defined($ARGV[1])) {
		$ask_redmine_api_key = (defined($ask_redmine_api_key) && $ask_redmine_api_key ne '{{ask_redmine_api_key}}' && $ask_redmine_api_key ne '' && lc($ask_redmine_api_key) ne 'skip')?$ask_redmine_api_key:'';
		if ($ask_redmine_api_key ne '' || (defined($ARGV[0]) && !defined($ARGV[1]))) {
			$question = "Q7. Do you want to change Redmine API key?(y/N)";
			$answer = "A7. Skip Set Redmine API key!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q7. Please enter the Redmine API key:(If your Redmine has not been set up, please enter 'SKIP')";
			$ask_redmine_api_key = prompt_for_input($question);
			$isAsk = ($ask_redmine_api_key eq '');
			if ($isAsk) {
				print("A7. The API key is empty, please re-enter!\n");
			}
			else {
				$answer = "A7. Set Redmine API key OK!";
			}
		}
	}
	else {
		$ask_redmine_api_key = $ARGV[1];
		$answer = "A7. Set Redmine API key OK!";
	}
	print ("$answer\n\n");
	if ($ask_redmine_api_key ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_redmine_api_key;
			require($p_config_tmpl_ans);
			$ask_redmine_api_key=$tmp;
		}
		write_ans();
	}
}

# 8. set Harbor admin password
#\$ask_harbor_admin_password = '{{ask_harbor_admin_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'ask_harbor_admin_password') {
	if (!defined($ARGV[1])) {
		$password1 = (defined($ask_harbor_admin_password) && $ask_harbor_admin_password ne '{{ask_harbor_admin_password}}' && $ask_harbor_admin_password ne '')?$ask_harbor_admin_password:'';
		if ($password1 ne '') {
			$question = "Q8. Do you want to change Harbor admin password?(y/N)";
			$answer = "A8. Skip Set Harbor admin password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q8. Please enter the Harbor admin password:(If it is the same as GitLab, please enter 'SAME')";
			$password1 = prompt_for_password($question);
			if (lc($password1) eq 'same') {
				$password1 = $same_passwd;
				$isAsk = 0;
			}
			else {
				$question = "Q8. Please re-enter the Harbor admin password:";
				$password2 = prompt_for_password($question);
				$isAsk = !(($password1 eq $password2) && ($password1 ne ''));
			}
			if ($isAsk) {
				print("A8. The password is not the same, please re-enter!\n");
			}
			else {
				$answer = "A8. Set Harbor admin password OK!";
			}
		}
	}
	else {
		$password1 = $ARGV[1];
		$answer = "A8. Set Harbor admin password OK!";
	}
	$ask_harbor_admin_password = $password1;
	print ("$answer\n\n");
	if ($ask_harbor_admin_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$ask_harbor_admin_password;
			require($p_config_tmpl_ans);
			$ask_harbor_admin_password=$tmp;
		}
		write_ans();
	}
}

# 9. set III-DevOps settings(Core)
require($Bin.'/generate_env_iiidevops.pl');

# 10a. Automatically generate password
#\$auto_password = '{{auto_password}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'auto_password') {
	if (!defined($ARGV[1])) {
		$auto_password = (defined($auto_password) && $auto_password ne '{{auto_password}}' && $auto_password ne '')?$auto_password:'';
		if ($auto_password ne '') {
			$question = "Q10a. Do you want to change auto password?(y/N)";
			$answer = "A10a. Skip Set auto password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		if ($isAsk) {
			$auto_password = random_password(20);
			$answer = "A10a. Set auto password OK!";
		}
	}
	else {
		$auto_password = $ARGV[1];
		$answer = "A10a. Set auto password OK!";
	}
	print ("$answer\n\n");
	if ($auto_password ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$auto_password;
			require($p_config_tmpl_ans);
			$auto_password=$tmp;
		}
		write_ans();
	}
}

# 10b. Automatically generate random key
#\$random_key = '{{random_key}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'random_key') {
	if (!defined($ARGV[1])) {
		$random_key = (defined($random_key) && $random_key ne '{{random_key}}' && $random_key ne '')?$random_key:'';
		if ($random_key ne '') {
			$question = "Q10b. Do you want to change auto password?(y/N)";
			$answer = "A10b. Skip Set auto password!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		if ($isAsk) {
			$random_key = random_password(20);
			$answer = "A10b. Set random key OK!";
		}
	}
	else {
		$random_key = $ARGV[1];
		$answer = "A10b. Set random key OK!";
	}
	print ("$answer\n\n");
	if ($random_key ne '') {
		if (-e $p_config_tmpl_ans) {
			$tmp=$random_key;
			require($p_config_tmpl_ans);
			$random_key=$tmp;
		}
		write_ans();
	}
}

#------------------------------
# checkmarx setting(Option)
#------------------------------
if (!defined($ARGV[0])) {
	$question = "Q11. Do you want to change Checkmarx setting(Option)?(y/N)";
	$answer = "A11. Skip Set Checkmarx setting!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk = 1;
}
if ($isAsk) {
	require($Bin.'/generate_env_checkmarx.pl');
}

#------------------------------
# WebInspect setting(Option)
#------------------------------
if (!defined($ARGV[0])) {
	$question = "Q12. Do you want to change WebInspect setting(Option)?(y/N)";
	$answer = "A12. Skip Set WebInspect setting!";
	$Y_N = prompt_for_input($question);
	$isAsk = (lc($Y_N) eq 'y');	
}
else {
	$isAsk = 1;
}
if ($isAsk) {
	require($Bin.'/generate_env_webinspect.pl');
}


#------------------------------
# 21. Generate env.pl
#------------------------------
$question = "Q21. Do you want to generate env.pl based on the above information?(Y/n)";
$Y_N = prompt_for_input($question);
if (lc($Y_N) ne 'n') {
	if (-e $p_config) {
		`cat $p_config > $p_config_bak`;
		print("The original env.pl has been backed up as $p_config_bak\n");
	}
	
	$env_template = `cat $p_config_tmpl`;
	$env_template =~ s/{{vm1_ip}}/$vm1_ip/g;
	$env_template =~ s/{{vm2_ip}}/$vm2_ip/g;
	$env_template =~ s/{{ask_gitlab_root_password}}/$ask_gitlab_root_password/g;
	$env_template =~ s/{{ask_gitlab_private_token}}/$ask_gitlab_private_token/g;
	$env_template =~ s/{{ask_rancher_admin_password}}/$ask_rancher_admin_password/g;
	$env_template =~ s/{{ask_redmine_admin_password}}/$ask_redmine_admin_password/g;
	$env_template =~ s/{{ask_redmine_api_key}}/$ask_redmine_api_key/g;
	$env_template =~ s/{{ask_harbor_admin_password}}/$ask_harbor_admin_password/g;
	$env_template =~ s/{{auto_password}}/$auto_password/g;
	$env_template =~ s/{{random_key}}/$random_key/g;
	$env_template =~ s/{{checkmarx_origin}}/$checkmarx_origin/g;
	$env_template =~ s/{{checkmarx_username}}/$checkmarx_username/g;
	$env_template =~ s/{{checkmarx_password}}/$checkmarx_password/g;
	$env_template =~ s/{{checkmarx_secret}}/$checkmarx_secret/g;	
	$env_template =~ s/{{webinspect_base_url}}/$webinspect_base_url/g;
	$env_template =~ s/{{ask_admin_init_login}}/$ask_admin_init_login/g;
	$env_template =~ s/{{ask_admin_init_email}}/$ask_admin_init_email/g;
	$env_template =~ s/{{ask_admin_init_password}}/$ask_admin_init_password/g;
	
	open(FH, '>', $p_config) or die $!;
	print FH $env_template;
	close(FH);
	if (-e $p_config_bak) {
		$cmd_msg = `diff $p_config $p_config_bak`;
	}
	else {
		$cmd_msg = `cat $p_config`;
	}
	print("-----\n$cmd_msg-----\n");
}
# No longer needed 

exit;


sub write_ans {

	$ans_file = $ans_tmpl;
	$ans_file =~ s/{{vm1_ip}}/$vm1_ip/;
	$ans_file =~ s/{{vm2_ip}}/$vm2_ip/;
	$ans_file =~ s/{{ask_gitlab_root_password}}/$ask_gitlab_root_password/;
	$ans_file =~ s/{{ask_gitlab_private_token}}/$ask_gitlab_private_token/;
	$ans_file =~ s/{{ask_rancher_admin_password}}/$ask_rancher_admin_password/;
	$ans_file =~ s/{{ask_redmine_admin_password}}/$ask_redmine_admin_password/;
	$ans_file =~ s/{{ask_redmine_api_key}}/$ask_redmine_api_key/;
	$ans_file =~ s/{{ask_harbor_admin_password}}/$ask_harbor_admin_password/;
	$ans_file =~ s/{{auto_password}}/$auto_password/;
	$ans_file =~ s/{{random_key}}/$random_key/;
	$ans_file =~ s/{{checkmarx_origin}}/$checkmarx_origin/;
	$ans_file =~ s/{{checkmarx_username}}/$checkmarx_username/;
	$ans_file =~ s/{{checkmarx_password}}/$checkmarx_password/;
	$ans_file =~ s/{{checkmarx_secret}}/$checkmarx_secret/;
	$ans_file =~ s/{{webinspect_base_url}}/$webinspect_base_url/;
	$ans_file =~ s/{{ask_admin_init_login}}/$ask_admin_init_login/;
	$ans_file =~ s/{{ask_admin_init_email}}/$ask_admin_init_email/;
	$ans_file =~ s/{{ask_admin_init_password}}/$ask_admin_init_password/;
	
	open(FH, '>', $p_config_tmpl_ans) or die $!;
	print FH $ans_file;
	close(FH);
	
	return;	
}


# Ref - http://www.tizag.com/perlT/perluserinput.php
sub prompt_for_input {
	my ($p_question) = @_;
    print "$p_question";
	my $answer = <STDIN>;
    $answer =~ s/\R\z//;

    return $answer;
}

# Ref - https://stackoverflow.com/questions/39801195/how-can-perl-prompt-for-a-password-without-showing-it-in-the-terminal
sub prompt_for_password {
	my ($p_question) = @_;
	# Check password rule
	my $regex = qr/(?=.*\d)(?=.*[a-z])(?=.*[A-Z])^[\w!@#$%^&*()+|{}\[\]`~\-\'\";:\/?.\\>,<]{8,20}$/mp;	

	require Term::ReadKey;
	
	my $password = '';
	while(!($password =~ /$regex/g) && lc($password) ne 'same') {
		# Tell the terminal not to show the typed chars
		Term::ReadKey::ReadMode('noecho');
		print "$p_question";
		$password = Term::ReadKey::ReadLine(0);
		# Rest the terminal to what it was previously doing
		Term::ReadKey::ReadMode('restore');
		print "\n";

		# get rid of that pesky line ending (and works on Windows)
		$password =~ s/\R\z//;
	}

    return $password;
}

# Ref - https://utdream.org/quick-random-password-generator-for-perl/
sub random_password {
	my ($password_len) = @_;
	my @alphanumeric = ('a'..'z', 'A'..'Z', 0..9); #('a'..'z', 'A'..'Z', 0..9,'!','_','-');
	my @numeric = (0..9);
	my $randpassword = '';
	my $password_len_max = ($password_len>0)?$password_len:16;
	

	until ( length($randpassword) > $password_len_max ) {
        $randpassword = $randpassword . join '', map $alphanumeric[rand @alphanumeric], 0..(rand @numeric);
	}
	
	return($randpassword);
}