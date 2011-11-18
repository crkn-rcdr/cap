package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use POSIX qw(strftime);
use feature "switch";

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub key :Path("") :Args(1) {
    my($self, $c, $key) = @_;
    $c->forward("view", [$key, undef]);
    return 1;
}

sub key_seq :Path("") :Args(2) {
    my($self, $c, $key, $seq) = @_;
    $c->forward("view", [$key, $seq]);
    return 1;
}

sub view :Private {
    my($self, $c, $key, $seq) = @_;

    my $doc = $c->model("Solr")->document($key);
    $c->detach("/error", [404, "Record not found: $key"]) unless $doc;

    given ($doc->record_type) {
        when ('series') {
            if ($seq) {
                $c->detach("/error", [404, "Series does not contain issue $seq: $key"]) unless $doc->child($seq);
                $c->response->redirect($c->uri_for_action("view/key", $doc->child($seq)->key));
            }
            $c->forward("view_series", [$doc]);
        } when ('document') {
            $seq = $seq || 1;
            $c->forward("view_doc", [$doc, $seq]);
        } when ('page') {
            $c->response->redirect($c->uri_for_action("view/key_seq", $doc->pkey, $doc->seq));
        } default {
            $c->detach("/error", [404, "Record has unsupported type $doc->type: $key"]);
        }
    }

    return 1;
}

sub view_doc :Private {
    my ($self, $c, $doc, $seq) = @_;
    my $page = $doc->set_active_child($seq);
    my $size;

    if ($page) {
        $size = $self->get_size($c, $page);
        $c->stash(
            derivative_access => $c->forward("/user/has_access", [$page, $doc->key, 'derivative', $size]),
            download_access => $c->forward("/user/has_access", [$page, $doc->key, 'download', $size]),
        );
    }

    $c->stash(
        doc => $doc,
        template => "view_doc.tt",
        access_level => $c->forward("/user/access_level", [$doc]),
    );
    return 1;
}

sub view_series :Private {
    my ($self, $c, $doc) = @_;
    $c->stash(
        doc => $doc,
        template => "view_series.tt"
    );
    return 1;
}

sub get_size {
    my ($self, $c, $page) = @_;
    my $size = $c->config->{derivative}->{default_size};
    if ($c->req->params->{s} && $c->config->{derivative}->{size}->{$c->req->params->{s}}) {
        $size = $c->config->{derivative}->{size}->{$c->req->params->{s}};
    }
    return $size;
}

# Select a random document
sub random : Path('/viewrandom') Args() {
    my($self, $c) = @_;
    my $solr = $c->stash->{solr};

    # Pick a document at random
    my $ndocs = $solr->count({}, { type => 'document' });
    my $index = int(rand() * $ndocs) + 1;

    # Get the record
    my $doc = $solr->query({}, { type => 'document', page => $index, solr => { rows => 1 } })->{documents}->[0];
    if ($doc) {
        $c->res->redirect($c->uri_for_action('view', $doc->key));
        return 1;
    }
    $c->detach('/error', [500, "Failed to retrieve document"]);
}

__PACKAGE__->meta->make_immutable;

