package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use POSIX qw(strftime);
use feature "switch";
no warnings "experimental::smartmatch";
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

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

    my $doc = $c->model("Solr")->document($key, text => $text, subset => $c->portal->subset);
    $c->detach("/error", [404, "Record not found: $key"]) unless $doc && $doc->found;

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
            $c->auth->title_context($c->model('DB::Titles')->find($doc->record->cap_title_id));
            $doc->authorize($c->auth);
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
        my $size = 1;
        my $rotate = 0;
        if (defined($c->request->query_params->{s}) && defined($c->config->{derivative}->{size}->{$c->request->query_params->{s}})) {
            $size = int($c->request->query_params->{s});
        }
        if (defined($c->request->query_params->{r}) && defined($c->config->{derivative}->{rotate}->{$c->request->query_params->{r}})) {
            $rotate = int($c->request->query_params->{r});
        }

        $c->stash(
            doc => $doc,
            rotate => $rotate,
            size => $size,
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
    my $search = $c->model('Solr')->search({ pkey => $doc->key, t => 'issue' }, $c->portal->subset);
    # FIXME: Hardcoded portal ids are fun
    my $rows = $c->portal->id eq 'parl' ? $search->count() : 20;

    my $options = {
        'sort' => 'seq asc',
        'fl'   => 'key,pkey,label,pubmin,pubmax,type,contributor,canonicalUri',
        'rows' => $rows,
    };
    my $issues;
    eval { $issues = $search->run(options => $options, page => $page) };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->stash(
        doc => $doc,
        issues => $issues,
        template => "view_series.tt"
    );

    # TODO: figure out a better solution than hardcoding this
    if ($c->portal->id eq 'parl') {
        my @tree = $c->model('DB::Terms')->term_tree($c->portal);
        $c->stash(
            browse => \@tree,
            id_prefix => "oop.",
        );
    }
    return 1;
}

# Select a random document
sub random : Path('/viewrandom') Args() {
    my($self, $c) = @_;

    my $doc;
    eval {
        $doc = $c->model('Access::Search')->random_document({
            root_collection => $c->portal->id
        })->{resultset}{documents}[0];
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->res->redirect($c->uri_for_action('view/key', $doc->{key}));
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

