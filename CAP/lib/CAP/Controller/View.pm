package CAP::Controller::View;
use Moose;
use namespace::autoclean;
use POSIX qw(strftime);

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::View - Catalyst Controller

=cut

sub record :Path("") :Args(1) {
    my($self, $c, $key) = @_;
    $c->forward('page', [$key, 1]);
}

sub page :Path("") :Args(2) {
    my($self, $c, $key, $seq) = @_;

    my $doc = $c->model('Solr')->document($key);
    $c->detach('/error', [404, "Record not found: $key"]) unless ($doc);
    $doc->active_child($seq);


    # STUFF TO BE REMOVED WHEN NO LONGER NEEDED
    my $solr   =  $c->stash->{solr};
    my $page;
    if ($doc->type_is('document')) { $page = $c->forward('get_page', [$key, $seq]); }
    $c->stash->{response}->{parent} = $solr->document($doc->pkey, 'label', 'key', 'canonicalUri') if ($doc->pkey);
    $c->stash->{response}->{doc} = $doc->struct;
    $c->stash->{access_level} = $c->forward('/user/access_level', [$doc->struct]);
    $c->stash->{response}->{page} = $page;
    $c->stash->{response}->{children} = {
        pages => $solr->count({pkey => $doc->key}, {type => 'page'}),
        docs  => $solr->count({pkey => $doc->key}, {type => 'document'}),
    };

    #TODO: try to clean this up a bit.
    my $template_suffix;
    if ($doc->type_is('series')) {
            warn "SERIES";
            $template_suffix = 's';
    }
    else {
            $template_suffix = 'd';
    }
    $c->stash->{hosted} && $c->stash->{hosted}->{contributor} && $doc->contributor eq $c->stash->{hosted}->{contributor} ? $template_suffix .= 'h' : 0 ;

    $c->stash(
        doc => $doc,
        template => "view_$template_suffix.tt",
    );
    warn "DONE " . $c->stash->{template};
    return 1;
}

# TO BE REMOVED WHEN NOT NEEDED
sub get_page :Private
{
    my($self, $c, $key, $seq) = @_;
    warn "$key, $seq";
    my $solr = $c->stash->{solr};
    my $result = $solr->query({}, { type => 'page', field => { pkey => $key , seq => $seq } });
    my $page = $result->{documents}->[0];
    $c->detach('/error', [404, "Page not found: seq $seq for $key"]) unless ($page);

    # can we view the page at this size?
    my $size   = $c->config->{derivative}->{default_size};
    if ($c->req->params->{s} && $c->config->{derivative}->{size}->{$c->req->params->{s}}) {
        $size = $c->config->{derivative}->{size}->{$c->req->params->{s}};
    }

    $c->stash->{derivative_access} = $c->forward('/user/has_access', [$page, $key, 'derivative', $size]);
    $c->stash->{download_access} = $c->forward('/user/has_access', [$page, $key, 'download', $size]);
    return $page;
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

