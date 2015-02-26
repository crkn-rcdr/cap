#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use File::Find::Rule;
use FindBin qw($Bin);
use Text::Trim;

my %collection_codes = (
	'English Canadian Literature' => 'ecl',
	'Genealogy' => 'glh',
	'Early Governors General of Canada' => 'gvg',
	'Early Official Publications' => 'gvp',
	'Hudson\'s Bay' => 'hbc',
	'History of French Canada' => 'hfc',
	'Health and Medicine' => 'hmd',
	'Jesuit Relations' => 'jsr',
	'Native Studies' => 'nas',
	'Periodicals' => 'per',
	'Canadian Women\'s History' => 'wmh',
);

my $out_filename = "$Bin/../conf/collection/all.csv";
my $out_fh;
unless (open($out_fh, '>>', $out_filename)) {
	print STDERR "Cannot open $out_filename for appending: $!\n";
	exit 1;
}


my $in_fh;
while (<$Bin/../conf/collection/intake/*.csv>) {
	print STDOUT "Processing $_\n";
	unless (open($in_fh, '<', $_)) {
		print STDERR "Cannot open $_ for reading: $!\n";
		next;
	}

	while(my $line = <$in_fh>) {
		trim $line;
		my ($id, $collection_names) = split(/,/, $line);
		$id = sprintf("%05s", $id) if (index($id, '_') == -1);
		$id = "oocihm.$id";
		my @line_codes = map {
			exists $collection_codes{trim $_} ? $collection_codes{trim $_} : 'FIXME';
		} split(/ *\| */, $collection_names);
		foreach my $c (@line_codes) {
			print $out_fh "$id,$c\n";
		}
	}

	close($in_fh);
	rename $_, $_ . '.processed';
}

close($out_fh);