#!/usr/bin/perl
# 18:47 2021/11/18
# Update perl and run the patch. (Working with devops-api)
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

$end_str = '==process complete==';

system("$Bin/p004.pl");

print("$end_str\n");
exit;
