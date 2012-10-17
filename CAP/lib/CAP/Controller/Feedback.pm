package CAP::Controller::Feedback;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_roles => [ 'NoSSL' ]
);

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
        $c->stash->{user_comments} = $user_comments;
        my $userid =  $c->user_exists ? $c->user->id : undef;
        my $insert = $c->model('DB::Feedback')->insert_feedback($userid, $user_comments);
        # my $username = $c->user->username;
        $c->stash->{full_name} = $c->user_exists ? $c->user->name : 'anonymous user' ;
        $c->stash->{user_name} = $c->user_exists ? $c->user->username : 'not logged in';
        $c->stash->{sending_message} = 0;
        # $c->forward("/mail/feedback");
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
