package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use parent 'Catalyst::Controller';

sub index :Path('') :Args(0) {
    my($self, $c) = @_;
    $c->detach('result_page', [1]);
}

sub result_page :Path('') :Args(1) {
    my($self, $c, $page) = @_;

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);

    my $options = {};

    my $subset = $c->stash->{search_subset};

    # Construct the main query:
    my $query = $c->model('Solr')->query;
    $query->limit_type($c->req->params->{t});
    $query->limit_date($c->req->params->{df}, $c->req->params->{dt});
    foreach my $field ($query->list_fields) { $query->append($c->req->params->{$field}, parse => 1, base_field => $field) }

    # Set query options
    $options->{sort} = $query->sort_order($c->req->params->{so});


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

1;
