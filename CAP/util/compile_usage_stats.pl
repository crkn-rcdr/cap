#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CIHM::UsageStats;
use Getopt::Long;
use JSON qw/decode_json encode_json/;

my $statsdb = 'http://localhost:5984/cap_usage_stats';
my $logfiledb = 'http://localhost:5984/cap_logfile_registry';
my $quiet = '';

GetOptions (
	'statsdb=s' => \$statsdb,
	'logfiledb=s' => \$logfiledb,
	'quiet' => \$quiet
);

unless (scalar @ARGV) {
	print "Usage: compile_usage_stats.pl <options?> <logfile(s)>\n\n";
	print "Options include: \n";
	print "--statsdb: database for compiled stats (default: http://localhost:5984/cap_usage_stats)\n";
	print "--logfiledb: database to register compiled logfiles (default: http://localhost:5984/cap_logfile_registry)\n";
	print "--quiet: output nothing to stdout\n";
	exit 1;
}

my $stats = {};
my $stats_server = CIHM::UsageStats->new({ statsdb => $statsdb, logfiledb => $logfiledb });
$stats_server->create_databases();

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
		increment(\$stats->{$stats_server->key($data->{portal}, $year, $month, 'user', $data->{user})}, $data);
		increment(\$stats->{$stats_server->key('total', $year, $month, 'user', $data->{user})}, $data);
	}
	if (defined $data->{institution}) {
		increment(\$stats->{$stats_server->key($data->{portal}, $year, $month, 'institution', $data->{institution})}, $data);
		increment(\$stats->{$stats_server->key('total', $year, $month, 'institution', $data->{institution})}, $data);
	}
	increment(\$stats->{$stats_server->key($data->{portal}, $year, $month)}, $data);
	increment(\$stats->{$stats_server->key('total', $year, $month)}, $data);
}

foreach ($stats_server->register_logfiles(@ARGV)) {
	my ($file, $already_registered) = @$_;
	if ($already_registered) {
		print "$file has already been processed.\n" unless $quiet;
		next;
	}

	if (-d $file) {
		print "$file is a directory.\n" unless $quiet;
		next;
	}

	open(my $fh, '<', $file) or die "Cannot open $file: $!";
	while (my $line = <$fh>) {
		$line =~ /^(\d{4})-(\d{2}).+ (\{.*\})$/;
		next unless ($1 && $2 && $3);
		handle_line($stats, $1, $2, decode_json($3));
	}
	close $fh;
}

my $updated_docs = $stats_server->update($stats);
print "$updated_docs doc(s) created or updated.\n" unless $quiet;
