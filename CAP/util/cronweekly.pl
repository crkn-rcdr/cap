#!/usr/bin/env perl

use strictures 2;
use utf8;

use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;
use DateTime;

my $scriptname = 'cronweekly';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

my @actions = (
    [status_report => \&status_report]
);

foreach (@actions) {
    my ($job, $ref) = @$_;
    eval { $ref->($c) };
    if ($@) {
        print STDERR "could not perform $job:\n$@";
    } else {
        # In the future we should log this, but for now we should be silent when not debugging.
        #print "performed $job\n";
    }
}

# Compile a system status report and send it to designated users
sub status_report {
    my $c = shift;

    my $portals = $c->model('Collections')->portals_with_titles('en');
    my $now = DateTime->now();

    $c->model('Mailer')->status_report($c, {
        portal_stats_current => $c->model('UsageStats')->status_report($portals, $now),
        portal_stats_previous => $c->model('UsageStats')->status_report($portals, $now->subtract(months => 1)),
    });

    return 1;
}
