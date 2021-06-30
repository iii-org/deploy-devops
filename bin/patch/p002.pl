#!/usr/bin/perl
#13:57 2021/6/30
# V1.5 ISO Bug Patch:

# Check running user
$cmd_msg = `whoami`;
$cmd_msg =~ s/\n|\r//g;
if ($cmd_msg ne 'rkeuser') {
	log_print("You must use the 'rkeuser' account to run the installation script!\n");
	exit;
}

$src_file = '/etc/apt/sources.list';
$back_file = $src_file.'.backup';
$cmd_msg = `cat $src_file`;
$chk_key = 'file:///home/rkeuser';
if (index($cmd_msg, $chk_key)<0) {
	print("Cannot find [$chk_key] in [$src_file], Skip patch!\n");
	exit;
}
else {
	if (!-e $back_file) {
		print("Cannot find backup file:[$back_file]!!! Patch failed!\n");
		exit;
	}
	system("sudo cp $src_file $src_file.local");
	system("sudo cp $back_file $src_file");
}	
