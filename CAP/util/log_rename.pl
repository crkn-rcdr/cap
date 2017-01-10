#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

my ($dir) = @ARGV;

unless (defined $dir) {
	print "Usage: log_rename.pl <directory>\n";
	exit 1;
}

unless (-d $dir) {
	print "Directory $dir does not exist\n";
	exit 1;
}

my $pattern = qr/.*\.\d+$/;

opendir my($dh), $dir;
chdir $dh;
foreach my $file (grep /$pattern/, readdir $dh) {
	next if -d $file;
	open my $fh, '<', $file;
	my $line = <$fh>;
	close $fh;

	$line =~ /^(\d{4}-\d{2}-\d{2})/;
	my $date = $1;
	next unless $date;

	$file =~ /(.*)$pattern/;
	my $new_file = "$date-$1";
	rename $file, $new_file;
}
closedir $dh;

exit;