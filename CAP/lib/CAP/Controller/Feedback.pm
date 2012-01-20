package CAP::Controller::Feedback;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Feedback - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->stash->{template} = "feedback.tt";
    $c->stash->{feedback_submitted} = 0;
    
    # Get the user comments, set to null if undef
    my $user_comments = defined($c->request->params->{feedback}) ? $c->request->params->{feedback} : "";
    
    # if the message has one or more characters, process
    if (length($user_comments)) {
        $c->stash->{feedback_submitted} = 1;
        my $userid =  $c->user_exists ? $c->user->id : undef;
        my $insert = $c->model('DB::Feedback')->insert_feedback($userid, $user_comments);
    }
    
    
    return 1;
    
}


=head1 AUTHOR

Milan Budimirovic,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
