package CAP::Controller::Search;

use strict;
use feature qw(switch);
use warnings;
use Moose;
use namespace::autoclean;
use parent qw/Catalyst::Controller::ActionRole/;
use Scalar::Util qw/looks_like_number/;

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
            #$c->session->{login_redirect} = $c->req->uri;
            $c->response->redirect($c->uri_for_action('/user/login'));
        }
        $c->detach();
    }

    return 1;
}

sub index :Path('') {
    my($self, $c, $handler, $page) = @_;
    $page = $page && looks_like_number($page) ? $page    :
                  looks_like_number($handler) ? $handler : 1;

    $handler = $handler && !looks_like_number($handler) ? $handler : 'general';

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);
    my $offset = ($page - 1) * 10;

    # Run the main search
    my $search;
    eval {
        $search = $c->model('Access::Search')->dispatch($handler, {
            root_collection => $c->portal->id,
            offset => $offset
        }, $c->req->params);
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    # Record the last search parameters
    $c->session->{$c->portal->id}->{search} = {
        start    => $page,
        params   => $c->req->params,
        hits     => $search->{resultset}->hits,
    };

    $c->stash(
        resultset  => $search->{resultset},
        query      => $search->{query},
        template   => 'search.tt',
    );

    return 1;
}

sub matching_pages :Path('matching_pages') {
    my($self, $c, $key, $rows, $start) = @_;
    $c->detach('/error', [404, "Can only be called through fmt=ajax"]) unless $c->stash->{current_view} eq 'Ajax';
    my $subset = $c->portal->subset;
    my $doc = $c->model('Solr')->document($key, subset => $subset);
    $c->stash( doc => $doc, page_search => $c->model('Solr')->search_document_pages($doc, $c->req->params, $subset, $rows, $start));
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
