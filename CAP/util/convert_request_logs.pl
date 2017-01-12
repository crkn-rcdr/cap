#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long;
use File::Path qw/make_path/;
use DBI;
use DateTime::TimeZone;
use DateTime::Format::MySQL;
use DateTime::Format::ISO8601;
use JSON;

my $dsn = 'dbi:mysql:cap_log;mysql_enable_utf8=1';
my $user = 'cap';
my $password = '';
my $start = '';
my $end = '';
my $logname = 'request.log';
my $quiet = '';

GetOptions (
	'dsn=s' => \$dsn,
	'user=s' => \$user,
	'password=s' => \$password,
	'start=s' => \$start,
	'end=s' => \$end,
	'logname=s' => \$logname,
        'quiet' => \$quiet
);

my ($dir) = @ARGV;
$dir //= '.';

make_path $dir unless (-d $dir);
chdir $dir;

my $dbh = DBI->connect($dsn, $user, $password);

# get start date
my $date_ptr;
if ($start) {
	$date_ptr = DateTime::Format::ISO8601->parse_datetime($start);
} else {
	my $first_date_st = $dbh->prepare("select time from requests order by time asc limit 1");
	$first_date_st->execute();
	$date_ptr = DateTime::Format::MySQL->parse_datetime($first_date_st->fetchrow);
}

# get end date
my $end_date;
if ($end) {
	$end_date = DateTime::Format::ISO8601->parse_datetime($end);
} else {
	my $last_date_st = $dbh->prepare("select time from requests order by time desc limit 1");
	$last_date_st->execute();
	$end_date = DateTime::Format::MySQL->parse_datetime($last_date_st->fetchrow);
}

print "Converting logs from " . $date_ptr->date . " to " . $end_date->date . " (inclusive).\n" unless $quiet;
$end_date->add({days => 1});

# build logs
my $tz = DateTime::TimeZone->new(name => 'local');
sub transform {
	my ($row) = @_;
	my $time = DateTime::Format::MySQL->parse_datetime($row->{time})
		->set_time_zone($tz)
		->strftime('%Y-%m-%dT%H:%M:%S%z');

	my $data = { portal => $row->{portal}, action => $row->{action}, view => $row->{view} };
	$data->{args} = $row->{args} if $row->{args};
	$data->{user} = $row->{user_id} if $row->{user_id};
	$data->{institution} = $row->{institution_id} if $row->{institution_id};
	$data->{new_session} = JSON::true if $row->{session_count} == 1;
	
	return "$time " . encode_json($data) . "\n";
}

my $logs_st = $dbh->prepare("select * from requests where time >= ? and time < ?");

while (DateTime->compare($date_ptr, $end_date) == -1) {
	my $current_date = $date_ptr->date;
	$logs_st->execute($current_date, $date_ptr->add({days => 1})->date);
	next unless $logs_st->rows;

	my $row;
	open (my $fh, '>', "$current_date-$logname");
	while ($row = $logs_st->fetchrow_hashref) {
		print $fh transform($row);
	}
	print "Converted logs for $current_date.\n" unless $quiet;
	close $fh;
}
