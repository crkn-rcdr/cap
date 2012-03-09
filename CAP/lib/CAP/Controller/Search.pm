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

    # Create an empty q parameter if none was specified.
    $c->req->params->{q} = "" unless ($c->req->params->{q});

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);

    my $options = {};

    my $subset = $c->stash->{search_subset};

    # Construct the main query:
    my $query = $c->model('Solr')->query;
    $query->limit_type($c->req->params->{t});
    $query->limit_date($c->req->params->{df}, $c->req->params->{dt});

    my $query_string = $query->rewrite_query($c->req->params);
    my $base_field = $c->req->params->{field} || 'q';
    $query->append($query_string, parse => 1, base_field => $base_field);

    # Set query options
    $options->{sort} = $query->sort_order($c->req->params->{so});

    # Run the main search
    my $resultset = $c->model('Solr')->search($subset)->query($query->to_string, options => $options, page => $page);

    $c->stash(log_search => 1) if ($resultset);

    # Get the min and max publication dates for the set
    my $pubmin = $c->model('Solr')->search($subset)->pubmin($query->to_string) || 0;
    my $pubmax = $c->model('Solr')->search($subset)->pubmax($query->to_string) || 0;

    # Search within the text of the child records
    my $pages = {};
    my $response_pages = {};
    foreach my $doc (@{$resultset->docs}) {
        if ($doc->type_is('document') && $doc->child_count && ($c->req->params->{q} =~ /\S/ || $c->req->params->{tx} =~ /\S/)) {
            my $pg_query = $c->model('Solr')->query;
            $pg_query->append($c->req->params->{q}, parse => 1, base_field => 'q');
            $pg_query->append($c->req->params->{tx}, parse => 1, base_field => 'tx');
            $pg_query->append("pkey:" . $doc->key);
            my $pg_resultset = $c->model('Solr')->search($subset)->query($pg_query->to_string, options => { %{$options}, sort => $pg_query->sort_order('seq') } );
            if ($pg_resultset->hits) {
                $pages->{$doc->key} = $pg_resultset;
                $response_pages->{$doc->key} = {
                    result => $pg_resultset->api('result'),
                    docs   => $pg_resultset->api('docs'),
                };
            }
        }
    }

    # Record the last search parameters
    $c->session->{search} = {
        start    => $page,
        params   => $c->req->params,
        hits     => $resultset->hits,
    };

    $c->stash(
        pubmin    => int(substr($pubmin, 0, 4)),
        pubmax    => int(substr($pubmax, 0, 4)),
        pages     => $pages,
        resultset => $resultset,
        template  => 'search.tt',
    );

    return 1;
}

1;
