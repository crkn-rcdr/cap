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

    # Should we include the document text with the result?
    my $text = int($c->req->params->{api_text} || 0);

    my $doc = $c->model("Solr")->document($key, text => $text, subset => $c->stash->{search_subset});
    $c->detach("/error", [404, "Record not found: $key"]) unless $doc;

    # Put the document structure into the response object for use by the API.
    $c->stash->{response}->{doc} = $doc->record->api;

    given ($doc->record_type) {
        when ('series') {
            if ($seq) {
                $c->detach("/error", [404, "Series does not contain issue $seq: $key"]) unless $doc->child($seq);
                $c->response->redirect($c->uri_for_action("view/key", $doc->child($seq)->key));
            }
            $c->forward("view_series", [$doc]);
        } when ('document') {
            $doc->set_auth($c->stash->{access_model}, $c->user);
            $c->forward("view_doc", [$doc, $seq || 1]);
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

    $c->stash(
        doc => $doc,
        template => "view_doc.tt",
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

# Select a random document
sub random : Path('/viewrandom') Args() {
    my($self, $c) = @_;


    # Pick a document at random
    my $ndocs = $c->model('Solr')->search($c->stash->{search_subset})->count('type:document');
    my $index = int(rand() * $ndocs) + 1;

    # Get the record
    my $doc = $c->model('Solr')->search($c->stash->{search_subset})->nth_record('type:document', $index);
    $c->res->redirect($c->uri_for_action('view/key', $doc->key)) if ($doc);
    $c->detach('/error', [500, "Failed to retrieve document"]);
}

__PACKAGE__->meta->make_immutable;

