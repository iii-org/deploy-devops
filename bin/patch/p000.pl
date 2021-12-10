#!/usr/bin/perl
# 11:23 2021/12/10
# Update perl and run the patch.
# [V]Auto
# [ ]Manual
use FindBin qw($Bin);
$|=1; # force flush output

system("$Bin/p004.pl");

exit;
