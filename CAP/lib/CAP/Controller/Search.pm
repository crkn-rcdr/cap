package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use parent 'Catalyst::Controller';

sub index :Path('') :Args(0) {
    my($self, $c) = @_;
    $c->detach('result_page', [1]);
}

#sub index :Path("query") :Args(1) {
sub result_page :Path('') :Args(1) {
    my($self, $c, $page) = @_;

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);

    my $options = {};

    # Sorting
    given ($c->request->params->{so}) {
        when('oldest') {
            $options->{sort} = 'pubmin asc';
        }
        when('newest') {
            $options->{sort} = 'pubmax desc';
        }
        when('seq') {
            $options->{sort} = 'key asc, seq asc';
        }
        default {
            $options->{sort} = 'score desc';
        }
    }
    
    # Date (dr; df, dt)

    my $subset = $c->stash->{search_subset};


    # Construct the main query
    my $query = $c->model('Solr')->query;
    foreach my $field ($query->list_fields) {
        $query->append($c->req->params->{$field}, parse => 1, base_field => $field);
    }
    $query->append('type:(series OR document)', parse => 0);

    # Run the main search
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => $options, page => $page);

    # Get the min and max publication dates for the set
    my $pubmin = $c->model('Solr')->search($subset)->pubmin($query->to_string);
    my $pubmax = $c->model('Solr')->search($subset)->pubmax($query->to_string);

    # Search within the text of the child records
    my $pages = {};
    foreach my $doc (@{$resultset->docs}) {
        if ($doc->type_is('document') && $doc->child_count) {
            my $pg_query = $c->model('Solr')->query;
            $pg_query->append($c->req->params->{q}, parse => 1, base_field => 'q');
            $pg_query->append($c->req->params->{tx}, parse => 1, base_field => 'tx');
            $pg_query->append("pkey:" . $doc->key);
            my $pg_resultset = $c->model('Solr')->search($subset)->query($pg_query->to_string, options => $options);
            #$pages->{$doc->key} = $pg_resultset->api('result');
            #$pages->{$doc->key}->{documents} = $pg_resultset->api('docs');
            $pages->{$doc->key_periodsafe} = $pg_resultset if $pg_resultset->hits;
        }
    }

    #$c->stash->{response}->{result} = $resultset->api('result');
    #$c->stash->{response}->{result}->{pubmin} = $pubmin;
    #$c->stash->{response}->{result}->{pubmin_year} = substr($pubmin, 0, 4);
    #$c->stash->{response}->{result}->{pubmax} = $pubmax;
    #$c->stash->{response}->{result}->{pubmax_year} = substr($pubmax, 0, 4);
    #$c->stash->{response}->{facet} = $resultset->api('facets');
    #$c->stash->{response}->{set} = $resultset->api('docs');
    #$c->stash->{response}->{pages} = $pages;

    # Record the last search parameters
    $c->session->{search} = {
        start => $page,
        params => $c->req->params,
        hits => $resultset->hits,
    };

    $c->stash(
        pubmin    => substr($pubmin, 0, 4),
        pubmax    => substr($pubmax, 0, 4),
        pages     => $pages,
        resultset => $resultset,
        template  => 'search.tt',
    );

    return 1;
}


sub main_ :Private
{
    my($self, $c, $page, $solrparam) = @_;

    my $param = { page => 1 };
    $param->{'page'} = int($page) if ($page && int($page) && int($page) > 0);
    $param->{'solr'} = $solrparam || {};
    $param->{'type'} = $c->req->params->{'t'}  || undef;
    $param->{'sort'} = $c->req->params->{'so'} || undef;
    $param->{'allfields'} = 1 if ($c->req->params->{'allfields'});

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


sub advanced :Private
{
    my($self, $c) = @_;
    my @query = ();
    my $adv_any = $c->req->params->{'adv_any'} || "";
    my $adv_all = $c->req->params->{'adv_all'} || "";
    my $adv_not = $c->req->params->{'adv_not'} || "";
    my $adv_fl  = $c->req->params->{'adv_fl'}  || $c->config->{adv}->{default_field};

    # Include the field name if we are using something other than the
    # default field. If the specified field is not one of the enabled
    # fields, treat as the default.
    if ($adv_fl eq $c->config->{adv}->{default_field}) {
        $adv_fl = "";
    }
    if ($c->config->{adv}->{fields}->{$adv_fl}) {
        $adv_fl .= ':';
    }
    else {
        $adv_fl = "";
    }

    # Add tokens (keywords and phrases) from the any, all and none fields
    # to the query string.
    my @adv_any = ();
    while ($adv_any =~ /((?:".*?")|(?:[^\+\-\"\s]+))/g) {
        my $token = $1;
        if (substr($token, 0, 1) eq '"') {
            $token =~ s/[*?-]/ /g;
        }
        push(@adv_any, $adv_fl . $token);
    }
    push(@query, join(' | ', @adv_any));

    while ($adv_all =~ /((?:".*?")|(?:[^\+\-\"\s]+))/g) {
        my $token = $1;
        if (substr($token, 0, 1) eq '"') {
            $token =~ s/[*?-]/ /g;
        }
        push(@query, $adv_fl . $token);
    }

    while ($adv_not =~ /((?:".*?")|(?:[^\+\-\"\s]+))/g) {
        my $token = $1;
        if (substr($token, 0, 1) eq '"') {
            $token =~ s/[*?-]/ /g;
        }
        push(@query, '-' . $adv_fl . $token);
    }

    $c->res->redirect($c->uri_for_action('search', { $c->config->{adv}->{default_field} => join(' ', @query) }));
}


sub search :Private
{
    my($self, $c, $query, $param) = @_;
    my $solr = $c->stash->{solr};

    $c->stash->{response}->{type} = 'set';
    
    my $result = $solr->query($query, $param);
    $c->stash->{log_search} = 1 if ($result);

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
        my $parent = {};
        $parent = $solr->document($doc->{pkey}, 'key', 'label', 'canonicalUri') if ($doc->{pkey});
        my $record = {
            parent => $parent,
            doc    => $doc,
        };

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
        start => $param->{page} || 1,
        params => $c->req->params,
        hits => $result->{hits},
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
        template => "search.tt",
    );

    return 1;
}

1;
