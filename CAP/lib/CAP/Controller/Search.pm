package CAP::Controller::Search;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub search : Chained('/base') PathPart('search') Args() 
{
    my($self, $c, $start) = @_;
    $start = 1 unless ($start);

    my $type = 'pages';
    my %types = (
        'all' => 'page OR monograph OR serial OR issue',
        'pages' => 'page',
        'titles' => 'monograph OR serial',
    );
    if ($types{$c->req->params->{t}}) {
        $type = $c->req->params->{t};
        $c->forward('prepare_search', [$types{$c->req->params->{t}}]);
    }
    else {
        $c->forward('prepare_search', ['page']);
    }

    if ($c->request->params->{gr}) {
        $c->forward('run_grouped_search', [$start]);
    }
    else {
        $c->forward('run_search', [$start]);
    }

    # Record the last search parameters
    $c->session->{search} = {
        type => $type,
        start => $start,
        params => $c->req->params,
    };

    $c->stash(
        search => {
            type => $type,
            grouped => $c->req->params->{gr},
        },
        search_type => $type, # DEPRECATED
        search_grouped => $c->request->params->{gr}, # DEPRECATED
        template => "search.tt",
    );
    return 1;
}

sub prepare_search : Private
{
    my($self, $c, $type) = @_;

    my $param = $c->stash->{param} = {};
    my $query = $c->stash->{query} = {};

    # Generate a set of Solr query parameters from the request parameters.
    $self->add_query($c, 'q');
    $self->add_query($c, 'ti');
    $self->add_query($c, 'au');
    $self->add_query($c, 'su');
    $self->add_query($c, 'no');
    $self->add_query($c, 'de');
    $self->add_query($c, 'tx');
    $self->add_query($c, 'kw');
    $self->add_query($c, 'gkey');
    $self->add_query($c, 'pkey');
    $self->add_query($c, 'ctype');
    $self->add_query($c, 'lang');

    # Date range searching
    if ($c->request->params->{dr}) {
        my($pubmin,$pubmax) = split('-', $c->request->params->{dr});
        $pubmax = $pubmin unless ($pubmax); # If no $pubmax is supplied
        # E.g. in the case of "1950-52"
        if (length($pubmax) < length($pubmin)) {
            my $len = length($pubmax);
            my $full_pubmax = $pubmin;
            $full_pubmax =~ s/.{$len}$/$pubmax/;
            $pubmax = $full_pubmax;
        }
        $c->stash->{query}->{_pubmax} = "[$pubmin-01-01T00:00:00Z TO *]";
        $c->stash->{query}->{_pubmin} = "[* TO $pubmax-12-31T23:59:59Z]";
    }

    # Solr parameters other than q
    $self->add_param($c, 'sort', 'so');

    $query->{_type} = $type;

    return 1;
}

sub run_search : Private
{
    my($self, $c, $start) = @_;
    my $solr = CAP::Solr->new($c->config->{solr});
    $c->stash->{result} = $solr->query($start, $c->stash->{query}, $c->stash->{param});

    #if ($c->stash->{result}->{hits}) {
        #my $previews = {};
        #foreach my $doc (@{$c->stash->{result}->{documents}}) {
        #    $previews->{$doc->{key}} =
        #        $solr->query(0, {pkey => $doc->{key}, type => 'file', role => 'master'})->{documents}->[0];
        #}
        #$c->stash->{previews} = $previews;
    #}

    return 1;
}

sub run_grouped_search : Private
{
    my($self, $c, $start) = @_;
    my $solr = CAP::Solr->new($c->config->{solr});
    $c->stash->{result} = $solr->query_grouped($start, $c->stash->{query}, $c->stash->{param});
    return 1;
}

sub add_query
{
    my($self, $c, $request_param, $solr_param) = @_;
    $solr_param = $request_param unless ($solr_param);
    # Treat a value of '-' as a null value (so that we can use checkboxes,
    # etc. in the interface)
    if ($c->request->params->{$request_param} && $c->request->params->{$request_param} ne '-') {
        $c->stash->{query}->{$solr_param} = $c->request->params->{$request_param};
    }
}

sub add_param
{
    my($self, $c, $solr_param, $request_param) = @_;
    # Treat a value of '-' as a null value (so that we can use checkboxes,
    # etc. in the interface)
    if ($c->request->params->{$request_param} && $c->request->params->{$request_param} ne '-') {
        $c->stash->{param}->{$solr_param} = $c->request->params->{$request_param};
    }
}


1;
