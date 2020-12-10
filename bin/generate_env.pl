#!/usr/bin/perl
# Generate iiidevops env information script
#
use Socket;
use Sys::Hostname;
use FindBin qw($Bin);

my $p_config_tmpl = "$Bin/../env.pl.tmpl";
if (!-e $p_config_tmpl) {
	print("The template file [$p_config_tmpl] does not exist!\n");
	exit;
}

# 0. get host IP
my $host = hostname();
my $host_ip = inet_ntoa(scalar gethostbyname($host || 'localhost'));

# 1. Set $vm1_ip
my $question = "Q1. Do you want to set [$host_ip] as the URL of the main service?(GitLab, Harbor...)? (Y/n)";
my $vm1_ip = '';
my $Y_N = prompt_for_input($question);
if (lc($Y_N) eq 'n') {
	$question = "Q1. Please enter the IP or domain name of the main service?(GitLab, Harbor...):";
	$vm1_ip = prompt_for_input($question);
}
else {
	$vm1_ip = $host_ip;
}
my $answer = "A1. Set [$vm1_ip] for the main service";
print ("$answer\n\n");

# 2. Set $vm2_ip
$question = "Q2. Please enter the IP or domain name of the application service?(Redmine, Sonarqube...):";
my $vm2_ip = prompt_for_input($question);
$answer = "A2. Set [$vm2_ip] for the application service";
print ("$answer\n\n");

# 3. set GitLab root password
my $isAsk=1;
while ($isAsk) {
	$question = "Q3. Please enter the GitLab root password:";
	my $password1 = prompt_for_password($question);
	$question = "Q3. Please re-enter the GitLab root password:";
	my $password2 = prompt_for_password($question);
	$isAsk = ($password1 ne $password2);
	if ($isAsk) {
		print("A3. The password is not the same, please re-enter!\n");
	}
}
$answer = "A3. Set GitLab root password";
print ("$answer\n");




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