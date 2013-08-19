package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;

BEGIN {extends 'Catalyst::Controller::ActionRole'; }

sub auto :Private {
    my($self, $c) = @_;

    my $search_enabled = $c->auth->is_enabled('searching');
    my $can_search = $c->auth->can_use('searching');

    # Check whether search is enabled and, if so, whether the user has
    # sufficient privileges to access it.
    if (! $search_enabled) {
        $c->res->redirect($c->uri_for_action('/index'));
        $c->detach();
    }
    elsif (! $can_search) {
        warn("Insufficient access to search");
        if ($c->user) {
            $c->res->redirect($c->uri_for_action('/index'));
        }
        else {
            $c->session->{login_redirect} = $c->req->uri;
            $c->response->redirect($c->uri_for_action('/user/login'));
        }
        $c->detach();
    }

    return 1;
}

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

    # Record the last search parameters
    $c->session->{$c->portal->id}->{search} = {
        start    => $page,
        params   => $c->req->params,
        hits     => $resultset->hits,
    };

    $c->stash(
        pubmin     => int(substr($pubmin, 0, 4)),
        pubmax     => int(substr($pubmax, 0, 4)),
        resultset  => $resultset,
        log_search => $resultset ? 1 : 0,
        template   => 'search.tt',
    );

    return 1;
}

sub matching_pages_initial :Path('matching_pages_initial') :Args(1) {
    my($self, $c, $key) = @_;
    $c->detach('matching_pages', [$key, 10, 0]);
    return 1;
}

sub matching_pages_remaining :Path('matching_pages_remaining') :Args(1) {
    my($self, $c, $key) = @_;
    $c->detach('matching_pages', [$key, $c->req->params->{rows}, 10]);
    return 1;
}

sub matching_pages :Private {
    my($self, $c, $key, $rows, $start) = @_;
    $c->detach('/error', [404, "Can only be called through fmt=ajax"]) unless $c->stash->{current_view} eq 'Ajax';
    my $subset = $c->portal->subset;
    my $doc = $c->model('Solr')->document($key, subset => $subset);
    $c->stash( doc => $doc, page_search => $c->model('Solr')->search_document_pages($doc, $c->req->params, $subset, $rows, $start));
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
