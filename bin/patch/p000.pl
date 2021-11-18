#!/usr/bin/perl
# 18:47 2021/11/18
# Update perl and run the patch.

# p004.pl
if (!-e "$nfs_dir/project-data") {
	system("~/deploy-devops/bin/patch/p004.pl");
}
