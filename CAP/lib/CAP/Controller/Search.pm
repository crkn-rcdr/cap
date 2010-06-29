package CAP::Controller::Search;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub search : Chained('/base') PathPart('search') Args() 
{
    my($self, $c, $start) = @_;
    $start = 1 unless ($start);

    $c->stash( response => { type => 'set' } );

    my $type = 'pages';
    my %types = (
        'all' => 'page OR monograph OR serial OR issue OR collection',
        'pages' => 'page',
        'titles' => 'monograph OR serial',
    );
    if ($types{$c->req->params->{t}}) {
        $type = $c->req->params->{t};
        $c->forward('prepare_search', [$types{$c->req->params->{t}}]);
    }
    else {
        $c->forward('prepare_search', [$types{all}]);
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
        #search_type => $type, # DEPRECATED
        #search_grouped => $c->request->params->{gr}, # DEPRECATED
        template => "search.tt",
    );
    return 1;
}

sub prepare_search : Private
{
    my($self, $c, $type) = @_;

    my $param = $c->stash->{param} = {};
    my $query = $c->stash->{query} = {};
    my $facet = $c->stash->{facet} = {
        facet => 'false',
        'facet.sort' => 'true',
        'facet.mincount' => 1,
        'facet.limit' => -1,
        'facet.field' => [],
    };

    # Generate a set of Solr query parameters from the request parameters.
    $self->add_query($c, 'q');
    $self->add_query($c, 'ti');
    $self->add_query($c, 'au');
    $self->add_query($c, 'su');
    $self->add_query($c, 'no');
    $self->add_query($c, 'de'); # Deprecated ??? - check schema
    $self->add_query($c, 'tx');
    $self->add_query($c, 'kw'); # Probably deprecated; currently does the same thing as q
    $self->add_query($c, 'gkey');
    $self->add_query($c, 'pkey');
    $self->add_query($c, 'media');
    $self->add_query($c, 'lang');
    $self->add_query($c, 'contributor');

    # Date range searching
    if ($c->req->params->{df}) {
        # The following date formats are allowed:
        # YYYY, YYYY-MM, YYYY-MM-DD, YYYY-MM-DDTHH:MM:SS,
        # YYYY-MM-DDTHH:MM:SS.mmm, YYYY-MM-DDTHH:MM:SS.mmmZ
        # TODO: check for invalid dates (e.g. 1900-02-30)
        if ($c->req->params->{df} =~ /^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d{3}(Z)?)?)?)?)?$/) {
            my $mask = '1000-01-01T00:00:00Z';
            my $date = $c->req->params->{df} . substr($mask, length($c->req->params->{df}));
            $c->stash->{query}->{_pubmax} = "[$date TO *]";
        }
    }
    if ($c->req->params->{dt}) {
        # See above for validation rules
        if ($c->req->params->{dt} =~ /^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d{3}(Z)?)?)?)?)?$/) {
            my $mask = '1000-01-01T00:00:00.000Z';
            my $date = $c->req->params->{dt} . substr($mask, length($c->req->params->{dt}));
            $c->stash->{query}->{_pubmin} = "[* TO $date]";
        }
    }
    # DR is deprecated - maybe
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

    # Add faceting (FIXME: TESTING)
    $facet->{facet} = 'true';
    $facet->{'facet.field'} = ['lang', 'media', 'contributor'];


    $query->{_type} = $type;

    return 1;
}

sub run_search : Private
{
    my($self, $c, $start) = @_;
    my $solr = CAP::Solr->new($c->config->{solr});
    $solr->status_msg('Search::run_search main query');
    #$c->stash->{result} = $solr->query($start, $c->stash->{query}, $c->stash->{param}, $c->stash->{facet});
    my $result = $solr->query($start, $c->stash->{query}, $c->stash->{param}, $c->stash->{facet});
    $c->stash->{result} = $result; # DEPRECATED

    $c->stash->{response}->{result} = {
        page => $result->{page},
        pages => $result->{pages},
        page_prev => $result->{page_prev},
        page_next => $result->{page_next},
        hits => $result->{hits},
        hits_from => $result->{hitsFrom},
        hits_to => $result->{hitsTo},
        hits_per_page => $result->{hitsPerPage},
    };
    $c->stash->{response}->{facet} = $solr->{facet_fields};

    # Create and store the result set.
    my $set = [];
    foreach my $doc (@{$result->{documents}}) {
        push(@{$set}, $c->forward('/common/build_item', [$solr, $doc])); 
    }
    $c->stash->{response}->{set} = $set;

    # If a non-empty set is returned, find the first and last publication
    # dates.
    if (@{$set} > 0) {
        my $doc;
        $c->stash->{param}->{'sort'} = 'pubmin asc';
        $solr->status_msg('Search::run_search: oldest pubdate in set');
        $doc = $solr->query_first($c->stash->{query}, $c->stash->{param});
        $c->stash->{response}->{result}->{pubmin} = $doc->{pubmin};
        $c->stash->{response}->{result}->{pubmin_year} = substr($doc->{pubmin}, 0, 4);
        $c->stash->{param}->{'sort'} = 'pubmax desc';
        $solr->status_msg('Search::run_search: newest pubdate in set');
        $doc = $solr->query_first($c->stash->{query}, $c->stash->{param});
        $c->stash->{response}->{result}->{pubmax} = $doc->{pubmax};
        $c->stash->{response}->{result}->{pubmax_year} = substr($doc->{pubmax}, 0, 4);
    }

    $c->stash->{response}->{solr} = $solr->status();
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
