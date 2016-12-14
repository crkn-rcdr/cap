#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CIHM::UsageStats;
use Getopt::Long;
use JSON qw/decode_json encode_json/;

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

my $stats = {};
my $stats_server = CIHM::UsageStats->new({ server => $server, statsdb => $statsdb, logfiledb => $logfiledb });

sub increment {
	my ($hrefref, $data) = @_;
	$$hrefref->{sessions} += 1 if $data->{new_session};
	$$hrefref->{searches} += 1 if ($data->{action} eq 'search');
	$$hrefref->{views}    += 1 if ($data->{action} eq 'view' || $data->{action} eq 'file/get_page_uri');
	$$hrefref->{requests} += 1;
}

sub handle_line {
	my ($stats, $year, $month, $data) = @_;
	if (defined $data->{user}) {
		increment(\$stats->{encode_json [$data->{portal}, $year, $month, 'user', $data->{user}]}, $data);
		increment(\$stats->{encode_json ['total', $year, $month, 'user', $data->{user}]}, $data);
	}
	if (defined $data->{institution}) {
		increment(\$stats->{encode_json [$data->{portal}, $year, $month, 'institution', $data->{institution}]}, $data);
		increment(\$stats->{encode_json ['total', $year, $month, 'institution', $data->{institution}]}, $data);
	}
	increment(\$stats->{encode_json [$data->{portal}, $year, $month]}, $data);
	increment(\$stats->{encode_json ['total', $year, $month]}, $data);
}

chdir $dir;
foreach my $file (glob $logpattern) {
	next if -d $file;

	my $file_already_registered = $stats_server->register_logfile($file);
	if ($file_already_registered) {
		print "$file has already been processed.\n";
		next;
	}

	open my $fh, '<', $file;
	while (my $line = <$fh>) {
		$line =~ /^(\d{4})-(\d{2}).+ (\{.*\})$/;
		next unless ($1 && $2 && $3);
		handle_line($stats, $1, $2, decode_json($3));
	}
	close $fh;
}

foreach my $key (keys %$stats) {
	$stats_server->update_or_create($key, $stats->{$key});
}
