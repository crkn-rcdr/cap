package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

__PACKAGE__->config(
    action_roles => [ 'NoSSL' ]
);

sub index :Path('') :Args(0) {
    my($self, $c) = @_;
    $c->detach('result_page', [1]);
}

sub result_page :Path('') :Args(1) {
    my($self, $c, $page) = @_;

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);

    my $subset = $c->portal->subset;
    my $searcher = $c->model('Solr')->search($c->req->params, $subset);

    # Run the main search
    my($resultset, $pubmin, $pubmax);
    eval {
        $resultset = $searcher->run(page => $page);
        $pubmin = $searcher->pubmin || 0;
        $pubmax = $searcher->pubmax || 0;
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    # Search within the text of the child records
    my $pages = $c->model('Solr')->search_pages($resultset, $c->req->params, $subset);

    # Record the last search parameters
    $c->session->{search} = {
        start    => $page,
        params   => $c->req->params,
        hits     => $resultset->hits,
    };

    $c->stash(
        pubmin     => int(substr($pubmin, 0, 4)),
        pubmax     => int(substr($pubmax, 0, 4)),
        pages      => $pages,
        resultset  => $resultset,
        log_search => $resultset ? 1 : 0,
        template   => 'search.tt',
    );

    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
