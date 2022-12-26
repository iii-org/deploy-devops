#!/usr/bin/perl
# 11:23 2021/12/10
# Update perl and run the patch.
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

$error_count=0;
$error_count += system("$Bin/p004.pl") >> 8;
$error_count += system("$Bin/p005.pl") >> 8;
$error_count += system("$Bin/p006.pl") >> 8;
$error_count += system("$Bin/p007.pl") >> 8;
if($error_count){
    exit($error_count);
}
else {
	exit;
}
