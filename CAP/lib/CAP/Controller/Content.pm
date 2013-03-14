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

    $c->stash(
        portal_titles => \@portal_content,
        contributor_titles => $c->model('DB::Titles')->counts_by_institution,
    );

    return 1;
}

=head2 unassigned($contributor)

List titles belonging to the specified institution that have not been assigned to any portals.

=cut
sub unassigned :Path('unassigned') :Args(1) {
    my ($self, $c, $institution_id) = @_;

    my $institution = $c->model('DB::Institution')->find({ id => $institution_id});
    if (! $institution) {
        $c->message({ type => "error", message => "institution_not_found" });
        $self->status_not_found( $c, message => "No such institution");
        return 1;
    }

    $c->stash(
        unassigned => [$c->model('DB::Titles')->unassigned($institution_id)->all],
        institution => $institution
    );

    return 1;
}

=head2 manage($id)

Display or update the portal assignments for title $id.

=cut
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

sub manage_POST {
    my($self, $c, $id) = @_;

    my $title = $c->model('DB::Titles')->find({ id => $id });
    if (! $title) {
        $c->message({ type => "error", message => "title_not_found" });
        $self->status_not_found( $c, message => "No such title");
        return 1;
    }

    my @portals = $c->model('DB::Portal')->search({})->all;

    my %data;
    foreach my $key (keys %{$c->req->body_parameters}) {
        $data{$key} = $c->req->body_parameters->{$key} if $c->req->body_parameters->{$key};
    }

    foreach my $portal (@portals) {
        my $value = int($c->req->body_parameters->{"portal-" . $portal->id} || 0);

        # Title should not be hosted by this portal
        if ($value == 0) {
            my $title = $c->model('DB::PortalsTitles')->find({ title_id => $id, portal_id => $portal->id});
            $title->delete if ($title);
        }

        # Title is indexed for searching but not hosted
        elsif ($value == 1) {
            $c->model('DB::PortalsTitles')->update_or_create(
                title_id => $id,
                portal_id => $portal->id,
                hosted => 0
            );
        }

        # Title is indexed and hosted
        elsif ($value == 2) {
            $c->model('DB::PortalsTitles')->update_or_create(
                title_id => $id,
                portal_id => $portal->id,
                hosted => 1
            );
        }
    }

    $c->response->redirect($c->uri_for_action('/content/manage', $id));
}

=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
