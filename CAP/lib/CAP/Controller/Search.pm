package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use parent 'Catalyst::Controller';


sub main :Private
{
    my($self, $c, $page, $solrparam) = @_;

    my $param = { page => 1 };
    $param->{'page'} = int($page) if ($page && int($page) && int($page) > 0);
    $param->{'solr'} = $solrparam || {};
    $param->{'type'} = $c->req->params->{'t'}  || undef;
    $param->{'sort'} = $c->req->params->{'so'} || undef;

    if ($c->req->params->{df} || $c->req->params->{dt}) {
        my $min = $c->req->params->{df} || $c->req->params->{dt};
        my $max = $c->req->params->{dt} || $c->req->params->{df};
        $param->{'date'} = [ $min, $max ];
    }
    elsif ($c->req->params->{'dr'}) {
        my($min, $max) = split(/\s*-\s*/, $c->req->params->{'dr'});
        $max = $min unless ($max); # If no $pubmax is supplied
        if (length($max) < length($min)) {
            my $len = length($max);
            my $full_max = $min;
            $full_max =~ s/.{$len}$/$max/;
            $max = $full_max;
        }
        $param->{'date'} = [ $min, $max ];
    }

    return $c->forward('search', [$c->req->params, $param]);
}

sub search :Private
{
    my($self, $c, $query, $param) = @_;
    my $solr = $c->stash->{solr};

    $c->stash->{response}->{type} = 'set';
    
    my $type = 'all'; # FIXME: get rid of this and in session update below;

    my $result = {};
    if ($c->request->params->{gr}) {
        #$c->forward('run_search', [$start, 1]);
        die "NOT IMPLEMENTED";
    }
    else {
        $result = $solr->query($query, $param);
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
        my $record = $c->forward('/common/build_item', [$solr, $doc, 1]);

        # Retrieve the first five pages from this item (if it has pages)
        # that match the general query string.
        if ($query->{q}) {
            $record->{pages} = $solr->query(
                { q => $query->{q}, pkey => $record->{doc}->{key} },
                { type => 'page', 'sort' => 'seq',
                    solr => { rows => 5, fl => 'key seq label canonicalUri' }
                }
            );
        }

        push(@{$set}, $record);
    }
    $c->stash->{response}->{set} = $set;

    # If a non-empty set is returned, find the first and last publication dates.
    if (@{$set} > 0) {
        $c->stash->{response}->{result}->{pubmin}      = $solr->limit($query, 'pubmin', 0);
        $c->stash->{response}->{result}->{pubmin_year} = substr($c->stash->{response}->{result}->{pubmin}, 0, 4);
        $c->stash->{response}->{result}->{pubmax}      = $solr->limit($query, 'pubmax', 1);
        $c->stash->{response}->{result}->{pubmax_year} = substr($c->stash->{response}->{result}->{pubmax}, 0, 4);
    }

    $c->stash->{response}->{solr} = $solr->status();

    # Record the last search parameters
    $c->session->{search} = {
        type => $type,
        start => $param->{page},
        params => $c->req->params,
    };

    # Remove any facets that don't have a corresponding label in the
    # labels stash. These may be either illegitimate values or values that
    # don't yet have a supported code->label mapping.
    my $facets = $c->stash->{response}->{facet};
    foreach my $facet (keys(%{$facets})) {
        my $i = 0;
        while ($i < @{$facets->{$facet}}) {
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
            #grouped => $c->req->params->{gr},
        },
        template => "search.tt",
    );

    return 1;
}

1;
