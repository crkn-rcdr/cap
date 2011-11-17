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
    $c->detach("error", [404, "Record not found: $key"]) unless ($doc);
    my $page = $doc->set_active_child($seq);
    $c->detach("error", [404, "Page not found: $seq for $key"]) unless $page;
    my $size = $c->forward('get_size', $page);

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
        derivative_access => $c->forward("/user/has_access", [$page, $doc->key, 'derivative', $size]),
        download_access => $c->forward("/user/has_access", [$page, $doc->key, 'download', $size]),
        access_level => $c->forward("/user/access_level", [$doc]),
    );
    warn "DONE " . $c->stash->{template};
    return 1;
}

sub get_size :Private {
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

