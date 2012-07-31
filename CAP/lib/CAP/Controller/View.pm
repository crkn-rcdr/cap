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

    my $doc = $c->model("Solr")->document($key, text => $text, subset => $c->search_subset);
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
            $doc->set_auth($c->stash->{access_model}, $c->session->{auth});
            $c->forward("view_doc", [$doc, $seq || $doc->record->first_page() ]);
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

    # Make sure we are asking for a valid page sequence.
    $c->detach("/error", [404, "Invalid sequence: $seq"]) unless ($seq && $seq =~ /^\d+$/);

    if ($doc->child_count > 0) {
        my $page = $doc->set_active_child($seq);

        # Make sure the requested page exists.
        $c->detach("/error", [404, "Page not found: $seq"]) unless $page;

        # Set image size and rotation
        if (defined($c->request->query_params->{s}) && defined($c->config->{derivative}->{size}->{$c->request->query_params->{s}})) {
            $c->session->{size} = $c->request->query_params->{s};
        }
        if (defined($c->request->query_params->{r}) && defined($c->config->{derivative}->{rotate}->{$c->request->query_params->{r}})) {
            $c->session->{rotate} = $c->request->query_params->{r};
        }

        $c->stash(
            doc => $doc,
            rotate => $c->session->{rotate} || 0,
            size => $c->session->{size} || 1,
            template => "view_doc.tt",
        );
    } else { # we don't have a document with pages
        $c->stash(
            doc => $doc,
            template => "view_doc.tt"
        );
    }
    return 1;
}

sub view_series :Private {
    my ($self, $c, $doc) = @_;

    my $page = ($c->req->params->{page} && int($c->req->params->{page} > 0)) ? int($c->req->params->{page}) : 1;

    my $subset = $c->stash->{search_subset};
    my $query = $c->model('Solr')->query;
    $query->limit_type('issue');
    $query->append("pkey:" . $doc->key);
    my $options = {
        'sort' => 'seq asc',
        'fl'   => 'key,pkey,label,pubmin,pubmax,type,contributor,canonicalUri',
        'rows' => 20,
    };
    my $issues;
    eval { $issues = $c->model('Solr')->search($subset)->query($query->to_string, options => $options, page => $page) };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->stash(
        doc => $doc,
        issues => $issues,
        template => "view_series.tt"
    );
    return 1;
}

# Select a random document
sub random : Path('/viewrandom') Args() {
    my($self, $c) = @_;


    # Pick a document at random
    my $ndocs;
    eval { $ndocs = $c->model('Solr')->search($c->search_subset)->count('type:document') };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);
    my $index = int(rand() * $ndocs) + 1;

    # Get the record
    my $doc;
    eval { $doc = $c->model('Solr')->search($c->search_subset)->nth_record('type:document', $index) };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);
    if ($doc) {
        $c->res->redirect($c->uri_for_action('view/key', $doc->key));
        $c->detach();
    }
    $c->detach('/error', [500, "Failed to retrieve document"]);
}

__PACKAGE__->meta->make_immutable;

