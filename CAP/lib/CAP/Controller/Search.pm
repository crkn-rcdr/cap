package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use parent 'Catalyst::Controller';

sub main :Private
{
    my($self, $c, $start) = @_;
    $start = 1 unless ($start);

    $c->stash->{response}->{type} = 'set';

    # By default, we search everything. If a type parameter is specified,
    # limit to records of a specific type.
    my $type = 'all';

    my %types = (
        'pages' => 'page',
        'titles' => 'monograph OR serial',
    );

    if ($c->req->params->{t} && $types{$c->req->params->{t}}) {
        $type = $c->req->params->{t};
        $c->forward('prepare_search', [$types{$c->req->params->{t}}]);
    }
    else {
        $c->forward('prepare_search', []);
    }

    if ($c->request->params->{gr}) {
        $c->forward('run_search', [$start, 1]);
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

    # Remove any facets that don't have a corresponding label in the
    # labels stash. These may be either illegitimate values or values that
    # don't yet have a supported code->label mapping.
    my $facets = $c->stash->{response}->{facet};
    foreach my $facet (keys(%{$facets})) {
        my $i = 0;
        while ($i < @{$facets->{$facet}}) {
            #warn $facets->{$facet}->[$i]->{name};
            if ($c->stash->{label}->{$facet}->{$facets->{$facet}->[$i]->{name}}) {
                ++$i;
            }
            else {
                splice(@{$facets->{$facet}}, $i, 1);
            }
        }
    }

    $c->stash(
        search   => {
            type    => $type,
            grouped => $c->req->params->{gr},
        },
        template => "search.tt",
    );

    return 1;

}


sub prepare_search : Private {

    my($self, $c, $type) = @_;

    my $param = $c->stash->{param} = {};
    my $query = $c->stash->{query} = {};
    my $facet = $c->stash->{facet} = {
        facet            => 'false',
        'facet.sort'     => 'true',
        'facet.mincount' => 1,
        'facet.limit'    => -1,
        'facet.field'    => [],
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
    $self->add_query($c, 'set');

    # Date range searching
    if ($c->req->params->{df}) {
        # The following date formats are allowed:
        # YYYY, YYYY-MM, YYYY-MM-DD, YYYY-MM-DDTHH:MM:SS,
        # YYYY-MM-DDTHH:MM:SS.mmm, YYYY-MM-DDTHH:MM:SS.mmmZ
        # TODO: check for invalid dates (e.g. 1900-02-30)
        if ($c->req->params->{df} =~ /^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d{3}(Z)?)?)?)?)?$/) {
            my $mask = '1000-01-01T00:00:00.000Z';
            my $date = $c->req->params->{df} . substr($mask, length($c->req->params->{df}));
            $c->stash->{query}->{_pubmax} = "[$date TO *]";
        }
    }

    if ($c->req->params->{dt}) {
        # See above for validation rules
        if ($c->req->params->{dt} =~ /^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}:\d{2}(\.\d{3}(Z)?)?)?)?)?$/) {
            my $mask = '1000-12-31T23:59:59.999Z';
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
    
    # Add sort order request
    $self->add_sort_order($c);

    # Add faceting
    $facet->{facet} = 'true';
    $facet->{'facet.field'} = ['lang', 'media', 'contributor', 'set'];

    # Limit results by type, if requested.
    $query->{_type} = $type if ($type);

    return 1;
}


sub run_search : Private {

    my($self, $c, $start, $grouped) = @_;
    my $solr = $c->stash->{solr};

    my $result;
    if ($grouped) {
        $result = $solr->search_grouped($c->stash->{query}, { page => $start });
    }
    else {
        $result = $solr->search($c->stash->{query}, {
            facets   => [ 'contributor', 'lang', 'media', 'set' ],
            page     => $start,
            'sort'   => $c->req->params->{so} || '',
        });
    }

    $c->stash->{response}->{result} = {
        page => $result->{page},
        pages => $result->{pages},
        prev_page => $result->{prev_page},
        next_page => $result->{next_page},
        hits => $result->{hits},
        hits_from => $result->{hitsFrom},
        hits_to => $result->{hitsTo},
        hits_per_page => $result->{hitsPerPage},
    };
    $c->stash->{response}->{facet} = $solr->{facet_fields};

    # Create and store the result set.
    my $set = [];
    foreach my $doc (@{$result->{documents}}) {
        push(@{$set}, $c->forward('/common/build_item', [$solr, $doc, 1])); 
    }
    $c->stash->{response}->{set} = $set;

    # If a non-empty set is returned, find the first and last publication dates.
    if (@{$set} > 0) {
        $c->stash->{response}->{result}->{pubmin}      = $solr->limit($c->stash->{query}, 'pubmin', 0);
        $c->stash->{response}->{result}->{pubmin_year} = substr($c->stash->{response}->{result}->{pubmin}, 0, 4);
        $c->stash->{response}->{result}->{pubmax}      = $solr->limit($c->stash->{query}, 'pubmax', 1);
        $c->stash->{response}->{result}->{pubmax_year} = substr($c->stash->{response}->{result}->{pubmax}, 0, 4);
    }

    $c->stash->{response}->{solr} = $solr->status();
    return 1;
}


sub add_query {

    my($self, $c, $request_param, $solr_param) = @_;
    $solr_param = $request_param unless ($solr_param);
    # Treat a value of '-' as a null value (so that we can use checkboxes,
    # etc. in the interface)
    if ($c->request->params->{$request_param} && $c->request->params->{$request_param} ne '-') {
        $c->stash->{query}->{$solr_param} = $c->request->params->{$request_param};
    }

}


# TODO: this looks to be deprecated.
#sub add_param {
#
#    my($self, $c, $solr_param, $request_param) = @_;
#    # Treat a value of '-' as a null value (so that we can use checkboxes,
#    # etc. in the interface)
#    if ($c->request->params->{$request_param} && $c->request->params->{$request_param} ne '-') {
#        $c->stash->{param}->{$solr_param} = $c->request->params->{$request_param};
#    }
#
#}



sub add_sort_order {
    
    my ($self, $c)  = @_;
    
    # map query string parameters onto solr parameters and add to solr request object
    given ($c->request->params->{'so'}) {

        when ('pubmin asc')        {$c->stash->{param}->{'sort'} = 'pubmin asc'}       # legacy
        when ('pubmax desc')       {$c->stash->{param}->{'sort'} = 'pubmax desc'}      # legacy
        when ('score desc')        {$c->stash->{param}->{'sort'} = 'score desc'}       # legacy
        when ('pkey asc,seq asc')  {$c->stash->{param}->{'sort'} = 'pkey asc,seq asc'} # legacy
        when ('score')             {$c->stash->{param}->{'sort'} = 'score desc'}
        when ('oldest')            {$c->stash->{param}->{'sort'} = 'pubmin asc'}
        when ('newest')            {$c->stash->{param}->{'sort'} = 'pubmax desc'}
        when ('seq')               {$c->stash->{param}->{'sort'} = 'pkey asc,seq asc'}
        default                    {$c->stash->{param}->{'sort'} = 'score desc'}

    }
    
    return 1;
}


1;
