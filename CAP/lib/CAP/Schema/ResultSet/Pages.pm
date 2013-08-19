package CAP::Schema::ResultSet::Pages;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head2 remove_transcription_lockfiles($timestamp)

Removes all transcription lockfiles that are older than
$timestamp and clears the transcriiber id column for each.
$timestamp is a DateTime object.

Returns the number of lockfiles removed.

=cut
sub remove_transcription_lockfiles {
    my($self, $timestamp) = @_;
    my $result = $self->search({
        transcription_status => 'locked_for_transcription',
        updated => { '<=' => $timestamp }
    });
    my $count = $result->count;

    while (my $page = $result->next) {
        $page->update({
            transcription_status => 'not_transcribed',
            transcription_user_id => undef
        });
    }

    return $count;
}

=head2 remove_review_locfiles($timestamp) 

Identical to remove_transcription_lockfiles() except that it removes stale reviewer locks.

=cut
sub remove_review_lockfiles {
    my($self, $timestamp) = @_;
    my $result = $self->search({
        transcription_status => 'locked_for_review',
        updated => { '<=' => $timestamp }
    });
    my $count = $result->count;

    while (my $page = $result->next) {
        $page->update({
            transcription_status => 'awaiting_review',
            review_user_id => undef
        });
    }

    return $count;
}

1;
