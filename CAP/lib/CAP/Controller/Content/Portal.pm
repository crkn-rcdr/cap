package CAP::Controller::Content::Portal;
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

CAP::Controller::Content::Portal - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub base : Chained('/') PathPart('content/portal') CaptureArgs(1) {
    my($self, $c, $portal_id) = @_;

    my $portal = $c->model('DB::Portal')->find({ id => $portal_id });
    if (! $portal) {
        $c->message({ type => "error", message => "portal_not_found" });
        $self->status_not_found( $c, message => "No such portal");
        $c->res->redirect($c->uri_for_action('/content/index'));
        $c->detach();
    }
    my $page = int($c->req->params->{page} || 1);

    $c->stash(
        entity => $portal,
        page => $page
    );
    return 1;
}

sub index : Chained('base') :PathPart('') :Args(0) {
    my($self, $c) = @_;
    my $portal = $c->stash->{entity};

    my $institution_counts = [];
    foreach my $institution (($c->model('DB::Titles')->institutions)) {
        my $titles = $c->model('DB::Titles')->titles_for_portal($portal, institution => $institution)->count;
        if ($titles) {
            my $hosted = $c->model('DB::Titles')->titles_for_portal($portal, institution => $institution, hosted => 1)->count;
            my $not_hosted = $c->model('DB::Titles')->titles_for_portal($portal, institution => $institution, hosted => 0)->count;
            push(@{$institution_counts}, { institution => $institution, titles => $titles, hosted => $hosted, not_hosted => $not_hosted });
        }
    }

    $c->stash(
        titles => $c->model('DB::Titles')->titles_for_portal($portal)->count,
        hosted => $c->model('DB::Titles')->titles_for_portal($portal, hosted => 1)->count,
        indexed => $c->model('DB::Titles')->titles_for_portal($portal, hosted => 0)->count,
        institution_counts => $institution_counts
    );
    return 1;
}

1;

