package CAP::Controller::Content::Title;
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

CAP::Controller::Content::Title - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') PathPart('content/title') CaptureArgs(1) {
    my($self, $c, $title_id) = @_;

    my $title = $c->model('DB::Titles')->find({ id => $title_id });
    if (! $title) {
        $c->message({ type => "error", message => "title_not_found" });
        $self->status_not_found( $c, message => "No such title");
        $c->res->redirect($c->uri_for_action('/content/index'));
        $c->detach();
    }

    $c->stash(
        entity => $title,
    );
    return 1;
}

sub index : Chained('base') :PathPart('') :Args(0) {
    my($self, $c) = @_;
    my $title = $c->stash->{entity};

    $c->stash(
        portal_list => [$c->model('DB::Portal')->list],
        portals => [$c->model('DB::PortalsTitles')->search({ title_id => $title->id })->all]
    );
    return 1;
}

sub add : Chained('base') :PathPart('add') :Args(0) {
    my($self, $c) = @_;
    my $title = $c->stash->{entity};
    my $portal_id = $c->req->params->{portal};
    my $hosted = $c->req->params->{hosted} || 0;
    $hosted = 1 if ($hosted);

    my $portal = $c->model('DB::Portal')->find({ id => $portal_id });
    if (! $portal) {
        $c->message({ type => "error", message => "portal_not_found" });
        $self->status_not_found( $c, message => "No such portal");
    }
    else {
        my $record = $c->model('DB::PortalsTitles')->update_or_create({
                portal_id => $portal->id,
                title_id => $title->id,
                hosted => $hosted
        });
        $c->message({ type => "success", message => "title_added_to_portal" });
    }

    warn $title->id;
    $c->res->redirect($c->uri_for_action('/content/title/index', [ $title->id ]));
    $c->detach();
}

sub remove : Chained('base') :PathPart('remove') :Args(1) {
    my($self, $c, $portal_id) = @_;
    my $title = $c->stash->{entity};

    my $record = $c->model('DB::PortalsTitles')->find({ portal_id => $portal_id, title_id => $title->id });
    if ($record) {
        $record->delete;
        $c->message({ type => "success", message => "title_removed" });
    }
    else {
        $c->message({ type => "error", message => "title_not_in_portal" });
        $self->status_not_found( $c, message => "No such title in portal");
    }
    $c->res->redirect($c->uri_for_action('/content/title/index', [ $title->id ]));
    $c->detach();
}

1;

