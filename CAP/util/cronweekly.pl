#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use lib "/opt/c7a-perl/current/cmd/local/lib/perl5";
use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;
use DateTime;

my $scriptname = 'cronweekly';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

my @actions = (
    [status_report             => \&status_report]
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

    # We need something in the portal ID field so that Mail won't
    # complain. FIXME: this is not a great solution.
    $c->stash(portal => 'Default');


    # If there is no one to send a status report to, then don't bother
    # doing any work.
    my $recipients =$c->config->{mailinglist}->{status_report};
    return 1 unless ($recipients);

    my $portals = $c->model('DB::Portal')->with_titles('en');
    my $now = DateTime->now();

    $c->controller('Mail')->status_report($c, $recipients,
        portal_stats_current => $c->model('UsageStats')->status_report($portals, $now),
        portal_stats_previous => $c->model('UsageStats')->status_report($portals, $now->subtract(months => 1)),
        user_subscriptions => [$c->model('DB::UserSubscription')->active_by_portal()]
    );

    return 1;
}
