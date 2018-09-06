#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;

my $scriptname = 'crondaily';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();

my $job;

# List of jobs to run. We can move this to the database or config file later.
# To create a new job put it in a sub and add it to this list.
# To disable a job just comment it out
my @actions = (
    [log_expired_accounts           => \&log_expired_accounts]
);

foreach (@actions) {
    my ($job, $ref) = @$_;
    eval { $ref->($c) };
    if ($@) {
        print STDERR "could not perform $job:\n$@";
    } else {
        # We should log this to a log4perl log, but otherwise stay silent when not debugging.
        #print "performed $job\n";
    }
}

sub expiring_subscription_reminder {
    # Contents of this subroutine have been deleted. We haven't successfully sent an
    # expiring subscription reminder since April 2015. We will revisit this issue when
    # it becomes a priority.
}


sub remove_unconfirmed {
    my $c = shift;

    my $days = $c->config->{confirm_grace_period};

    my $num_removed = $c->model('DB::User')->delete_unconfirmed($days);

    return 1;
}


sub session {
    my $c = shift;
    my $expired = $c->model('DB::Sessions')->remove_expired();
    return $expired;
}


sub log_expired_accounts {
    my $c = shift;
    my $log_expired = $c->model('DB::UserSubscription')->log_expired_subscriptions($c);
}
