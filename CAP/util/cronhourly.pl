#!/usr/bin/perl

use 5.010;
use strict;
use warnings;
use feature qw(switch say);

use FindBin;
use lib "$FindBin::Bin/../lib";

use CAP;

my $scriptname = 'cronhourly';

# Create a CAP object here so that you don't have to do it separately
# for each individual job.
my $c = CAP->new();


my  $set_pid = $c->model('DB::Info')->obtain_pid_lock( $scriptname, $$ );



unless (  $set_pid )  {
    $c->model('DB::CronLog')->create(
        {
            action     => 'cronhourly',
            ok              => 0,
            message => "$scriptname already running; killing myself as an example to others"
        }
    );
    die "cronhourly.pl: detected another version of myself, dying gracefully\nif the existing process is not responding please kill it and delete the cronhourly.pl row in cap.info";
}

my $job;

# List of jobs to run. We can move this to the database or config file later.
# To create a new job put it in a sub and add it to this list.
# To disable a job just comment it out
my %actions = (
    remove_transcription_locks      =>  \&remove_transcription_locks
);


foreach $job (keys(%actions)) {

    eval { $actions{$job}->($c) };
    if ( ($@) ) {
        $c->model('DB::CronLog')->create({
                   action      => 'cronhourly',
                   ok              => 0,
                   message => "error: $@; could not perform $job"
        });          
    }

}

my $delete_pid = $c->model('DB::Info')->delete_pid($scriptname, $$);

$c->model('DB::CronLog')->create({
               action        => 'cronhourly',
               ok                 => 1,
               message   => "done"
});


=head2 remove_transcription_locks

Remove any stale transcription lockfiles from cap.pages. Any lockfile more than 4 hours old will be removed.

=cut
sub remove_transcription_locks {
    my($c) = @_;
    my $cleared = 0;

    my $timestamp = DateTime->now();
    $timestamp->set_time_zone('local');
    $timestamp->subtract(DateTime::Duration->new( minutes => 1 ));
    $cleared += $c->model('DB::Pages')->remove_transcription_lockfiles($timestamp);
    $cleared += $c->model('DB::Pages')->remove_review_lockfiles($timestamp);

    if ($cleared) {
        $c->model('DB::CronLog')->create({
           action  => 'remove_transcription_locks',
           ok      => 1,
           message => "Cleared $cleared stale locks"
        });          
    }

}
