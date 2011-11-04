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
