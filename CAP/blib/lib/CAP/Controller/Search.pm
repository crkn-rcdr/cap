package CAP::Controller::Search;

use strict;
use warnings;
use parent 'Catalyst::Controller';

sub search : Chained('/base') PathPart('search') Args() 
{
    my($self, $c, $type, $start) = @_;
    $c->detach('/error', [404]) unless ($type);
    $start = 1 unless ($start);
    $c->stash->{template} = 'search/';
    $c->forward('prepare_search', [$type]);

    if ($c->request->params->{gr}) {
        $c->forward('run_grouped_search', [$start]);
        $c->stash->{template} = "search/${type}_gr.tt";
    }
    else {
        $c->forward('run_search', [$start]);
        $c->stash->{template} = "search/$type.tt";
    }

    # Record the last search parameters
    $c->session->{search} = {
        type => $type,
        start => $start,
        params => $c->req->params,
    };

    $c->stash->{result}->{hits} || $start <= $c->stash->{result}->{pages} or $c->stash->{template} = 'index.tt';
    $c->stash->{action} = 'search';
    return 1;
}

sub prepare_search : Private
{
    my($self, $c, $type) = @_;

    my $param = $c->stash->{param} = {};
    my $query = $c->stash->{query} = {};

    # Generate a set of Solr query parameters from the request parameters.
    $self->add_query($c, 'ti');
    $self->add_query($c, 'au');
    $self->add_query($c, 'su');
    $self->add_query($c, 'no');
    $self->add_query($c, 'tx');
    $self->add_query($c, 'kw');
    $self->add_query($c, 'gkey');
    $self->add_query($c, 'pkey');
    $self->add_query($c, 'ctype');
    $self->add_query($c, 'lang');

    # Date range searching
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

    # Solr parameters other than q
    $self->add_param($c, 'sort', 'so');

    # Determine what types to search based on the query type.
    if ($type eq 'titles') {
        $query->{_type} = "monograph OR serial" if ($type eq'titles');
    }
    elsif ($type eq 'pages') {
        $query->{_type} = "page";
    }
    else {
        # TODO: alternatively, we can accept $type as a literal value and
        # search whatever the user specifies.
        $c->detach('/error', [404]);
    }

    return 1;
}

sub run_search : Private
{
    my($self, $c, $start) = @_;
    my $solr = CAP::Solr->new($c->config->{Solr});
    $c->stash->{result} = $solr->query($start, $c->stash->{query}, $c->stash->{param});

    if ($c->stash->{result}->{hits}) {
        my $previews = {};
        foreach my $doc (@{$c->stash->{result}->{documents}}) {
            $previews->{$doc->{key}} =
                $solr->query(0, {pkey => $doc->{key}, type => 'file', role => 'master'})->{documents}->[0];
        }
        $c->stash->{previews} = $previews;
    }

    return 1;
}

sub run_grouped_search : Private
{
    my($self, $c, $start) = @_;
    my $solr = CAP::Solr->new($c->config->{Solr});
    $c->stash->{result} = $solr->query_grouped($start, $c->stash->{query}, $c->stash->{param});
    return 1;
}

sub add_query
{
    my($self, $c, $request_param, $solr_param) = @_;
    $solr_param = $request_param unless ($solr_param);
    if ($c->request->params->{$request_param}) {
        $c->stash->{query}->{$solr_param} = $c->request->params->{$request_param};
    }
}

sub add_param
{
    my($self, $c, $solr_param, $request_param) = @_;
    if ($c->request->params->{$request_param}) {
        $c->stash->{param}->{$solr_param} = $c->request->params->{$request_param};
    }
}


=head1 AUTHOR

William,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
