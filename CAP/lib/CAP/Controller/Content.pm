package CAP::Controller::Content;
use Moose;
use namespace::autoclean;
use CAP::Util;


__PACKAGE__->config(
    map => {
        'text/html' => [ 'View', 'Default' ],
    },
);

BEGIN { extends 'Catalyst::Controller::REST'; }

=head1 NAME

CAP::Controller::Content - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 auto

=cut
sub auto :Private {
    my($self, $c) = @_;

    # The content role is required for access
    unless ($c->has_role('content')) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        $c->detach();
    }

    return 1;
}


=head2 index

=cut

sub index :Path :Args(0) {
    my ($self, $c) = @_;

    my @portal_content = $c->model('DB::PortalsTitles')->counts_by_portal();
    my $unassigned = $c->model('DB::Titles')->unassigned();

    $c->stash(
        portal_content => \@portal_content,
        unassigned_count => $unassigned->count
    );

    return 1;
}

=head2 unassigned

List titles that have not been assigned to any portals

=cut
sub unassigned :Path('unassigned') :Args(0) {
    my ($self, $c) = @_;

    $c->stash(
        unassigned => [$c->model('DB::Titles')->unassigned()->all]
    );

    return 1;
}

sub manage :Local Path('manage') Args(1) ActionClass('REST') {
    my($self, $c, $id) = @_;
}

sub manage_GET {
    my($self, $c, $id) = @_;

    my $title = $c->model('DB::Titles')->find({ id => $id });
    if (! $title) {
        $c->message({ type => "error", message => "title_not_found" });
        $self->status_not_found( $c, message => "No such title");
        return 1;
    }

    $c->stash(
        entity => CAP::Util::build_entity($title),
        hosts => $c->model('DB::Portal')->hosts_for($title)
    );

    return 1;
}


=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
