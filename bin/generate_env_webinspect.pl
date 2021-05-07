#!/usr/bin/perl
#
#------------------------------
# WebInspect setting(Option)
#------------------------------

# 12. \$ask_webinspect_base_url = '{{ask_webinspect_base_url}}';
if (!defined($ARGV[0]) || $ARGV[0] eq 'webinspect_base_url') {
	if (!defined($ARGV[1])) {
		$ask_webinspect_base_url = (defined($ask_webinspect_base_url) && $ask_webinspect_base_url ne '{{webinspect_base_url}}' && $ask_webinspect_base_url ne '')?$ask_webinspect_base_url:'';
		if ($ask_webinspect_base_url ne '') {
			$question = "Q12. Do you want to change WebInspect URL?(y/N)";
			$answer = "A12. Skip Set WebInspect URL!";
			$Y_N = prompt_for_input($question);
			$isAsk = (lc($Y_N) eq 'y');	
		}
		else {
			$isAsk=1;
		}
		while ($isAsk) {
			$question = "Q12. Please enter the WebInspect URL:";
			$ask_webinspect_base_url = prompt_for_input($question);
			$isAsk = ($ask_webinspect_base_url eq '');
			if ($isAsk) {
				print("A12. The WebInspect URL is empty, please re-enter!\n");
			}
			else {
				$answer = "A12. Set WebInspect URL OK!";
			}
		}
	}
	else {
		$ask_webinspect_base_url = $ARGV[1];
		$answer = "A12. Set WebInspect URL OK!";
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

1;