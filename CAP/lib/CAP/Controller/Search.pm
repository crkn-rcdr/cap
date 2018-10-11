package CAP::Controller::Search;

use strict;
use warnings;
use Moose;
use namespace::autoclean;
use Scalar::Util qw/looks_like_number/;
use Types::Standard qw/Int/;

BEGIN { extends 'Catalyst::Controller'; }

# limit to matching page search return count
has 'matching_page_limit' => (
	is => 'ro',
	isa => Int,
	required => 1
);

sub index :Path('') {
    my($self, $c, $handler, $page) = @_;
    $page = $page && looks_like_number($page) ? $page    :
                  looks_like_number($handler) ? $handler : 1;

    $handler = $handler && !looks_like_number($handler) ? $handler : 'general';
    $c->detach('matching_pages') if ($handler eq 'page');

    # Retrieve the first page of results unless otherwise requested.
    $page = 1 unless ($page > 1);
    my $offset = ($page - 1) * 10;

    # Run the main search
    my $search;
    eval {
        $search = $c->model('Access::Search')->dispatch($handler, {
            root_collection => $c->portal_id,
            offset => $offset
        }, $c->req->params);
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->detach('/error', [400, "Solr error: " . $search->{error}{msg}]) if $search->{error};

    $c->stash(
        error          => $search->{error},
        resultset      => $search->{resultset},
        query          => $search->{query},
        search_handler => $handler ne 'general' ? $handler : '',
        template       => 'search.tt',
    );

    # Record the last search parameters
    $c->session->{$c->portal_id}->{search} = {
        start    => $page,
        params   => $c->req->params,
        hits     => $search->{resultset}->hits,
        query    => $search->{query}->cap_query,
        handler  => $handler ne 'general' ? $handler : '',
    };

    return 1;
}

sub matching_pages :Private {
    my ($self, $c) = @_;

    my $search;
    eval {
        $search = $c->model('Access::Search')->dispatch('page', { limit => $self->matching_page_limit }, $c->req->params);
    };
    $c->detach('/error', [503, "Solr error: $@"]) if ($@);

    $c->stash(
        resultset  => $search->{resultset},
        query      => $search->{query},
        template   => 'search.tt',
    );

    return 1;
}

sub post :Local {
    my ($self, $c) = @_;
    my $get_params = $c->model('Access::Search')->transform_query($c->req->params);
    my $handler = delete $get_params->{handler} || '';
    $c->response->redirect($c->uri_for_action('/search/index', $handler, $get_params));
    $c->detach();
}

__PACKAGE__->meta->make_immutable;

1;
