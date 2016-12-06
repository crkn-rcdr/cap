#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long;
use JSON qw/decode_json/;

my $server = 'http://localhost:5984/';
my $logpattern = '*.log';
my $statsdb = 'cap_usage_stats';
my $logfiledb = 'cap_logfile_registry';

GetOptions (
	'server=s' => \$server,
	'logpattern=s' => \$logpattern,
	'statsdb=s' => \$statsdb,
	'logfiledb=s' => \$logfiledb
);

my ($dir) = @ARGV;

unless (defined $dir) {
	print "Usage: compile_usage_stats.pl <options?> <directory>\n\n";
	print "Options include: \n";
	print "--server: couch server stats are compiled to (default: http://localhost:5984/)\n";
	print "--logpattern: glob pattern for logs (default: *.log)\n";
	print "--statsdb: database for compiled stats (default: cap_usage_stats)\n";
	print "--logfiledb: database to register compiled logfiles (default: cap_logfile_registry)\n";
	exit 1;
}

unless (-d $dir) {
	print "Directory $dir does not exist\n";
	exit 1;
}

my $stats = {
	user => {},
	institution => {},
	portal => {}
};

sub increment {
	my ($h, $year, $month, $data) = @_;
	$$h->{$year}{$month}{sessions} += 1 if $data->{new_session};
	$$h->{$year}{$month}{searches} += 1 if ($data->{action} eq 'search');
	$$h->{$year}{$month}{views}    += 1 if ($data->{action} eq 'view' || $data->{action} eq 'file/get_page_uri');
	$$h->{$year}{$month}{requests} += 1;
}

sub handle_line {
	my ($stats, $year, $month, $data) = @_;
	if (defined $data->{user}) {
		increment(\$stats->{user}{$data->{user}}{$data->{portal}}, $year, $month, $data);
		increment(\$stats->{user}{$data->{user}}{total}, $year, $month, $data);
	}
	if (defined $data->{institution}) {
		increment(\$stats->{institution}{$data->{institution}}{$data->{portal}}, $year, $month, $data);
		increment(\$stats->{institution}{$data->{institution}}{total}, $year, $month, $data);
	}
	increment(\$stats->{portal}{$data->{portal}}, $year, $month, $data);
}

chdir $dir;
foreach my $file (glob $logpattern) {
	next if -d $file;
	open my $fh, '<', $file;
	while (my $line = <$fh>) {
		$line =~ /^(\d{4})-(\d{2}).+ (\{.*\})$/;
		next unless ($1 && $2 && $3);
		handle_line($stats, $1, $2, decode_json($3));
	}
	close $fh;
}

#use Data::Dumper;
#print Dumper($stats) . "\n";
