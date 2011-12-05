package CAP::Solr::ResultSet;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

has server   => (is => 'ro', isa => 'Str', required => 1);
has response => (is => 'ro', isa => 'WebService::Solr::Response', required => 1);
has facets   => (is => 'ro', isa => 'HashRef', default => sub{{}}); # Parsed hash: { lang => { name => eng, count => 8 }, ... }
has facet    => (is => 'ro', isa => 'HashRef', default => sub{{}}); # List form: { lang => [ eng, 10, fra, 8, zho 2 ], }
has docs     => (is => 'ro', isa => 'ArrayRef', default => sub{[]});

has hits          => (is => 'ro', isa => 'Int', documentation => 'Number of records found');
has hits_from     => (is => 'ro', isa => 'Int', documentation => 'Position of the first record on this page');
has hits_per_page => (is => 'ro', isa => 'Int', documentation => 'Number of records per page of results');
has hits_to       => (is => 'ro', isa => 'Int', documentation => 'Position of the last record on this page');
has next_page     => (is => 'ro', isa => 'Int', default => 0, documentation => 'Number of the next page in the result set, or 0 if none');
has page          => (is => 'ro', isa => 'Int', default => 0, documentation => 'Current page of the result set');
has pages         => (is => 'ro', isa => 'Int', default => 0, documentation => 'Number of pages in the result set');
has prev_page     => (is => 'ro', isa => 'Int', default => 0, documentation => 'Number of the previous page in the result set, or 0 if none');
has query_time    => (is => 'ro', isa => 'Int', documentation => 'Query execution time in milliseconds');

method BUILD {
    # So we don't have to reference everything the long way:
    my $header   = $self->response->content->{responseHeader};
    my $response = $self->response->content->{response};

    # Generate the basic result information:
    
    # Number of hits (results) in the set.
    $self->{hits}          = $response->{numFound};

    # Number of hits displayed per page.
    $self->{hits_per_page} = $header->{params}->{rows};

    # Index of the first hit on this page (1 == first item)
    $self->{hits_from}     = $response->{start} + 1;

    # Index of the last hit on this page. We need to check for the special
    # case of a partial result (< hits_per_page) on the last page.
    $self->{hits_to}       = $self->hits_from + $self->hits_per_page - 1;
    $self->{hits_to}       = $self->hits if $self->hits_to > $self->hits;

    # Which page of results this is and how many pages of results in
    # total. In the case of no results, these default to zero. We also need to
    # check for results to avoid a division by zero error.
    if ($self->hits_per_page) {
        $self->{pages} = int($self->hits / $self->hits_per_page);
        $self->{pages} += 1 if ($self->hits % $self->hits_per_page);
        $self->{page} = int($self->hits_from / $self->hits_per_page) + 1;
    }

    # Next and previous pages in the result set. Defaults to 0 if the
    # current page is the last/first page in the set respectively.
    $self->{next_page} = $self->page + 1 if ($self->page < $self->pages);
    $self->{prev_page} = $self->page - 1 if ($self->page > 1);

    # Solr query execution time.
    $self->{query_time}    = $header->{QTime};


    # Get facet counts
    if ($self->response->facet_counts) {
        foreach my $facet (keys(%{$self->response->facet_counts->{facet_fields}})) {
            $self->{facets}->{$facet} = [];
            my @pairs = (@{$self->response->facet_counts->{facet_fields}->{$facet}});
            while (@pairs) {
                my $name   = shift(@pairs);
                my $count  = shift(@pairs);
                push(@{$self->{facets}->{$facet}}, { name => $name, count => $count });
            }

            # Don't parse they key-value pairs; leave them as a list.
            $self->{facet}->{$facet} = $self->response->facet_counts->{facet_fields}->{$facet};
        }
    }

    # Populate the docs list
    foreach my $doc ($self->response->docs) {
        push(@{$self->{docs}}, new CAP::Solr::Document({ server => $self->server, doc => $doc }));
    }

}

method api (Str $struct) {

    if ($struct eq 'result') {
        return {
            hits          => $self->hits,
            hits_from     => $self->hits_from,
            hits_to       => $self->hits_to,
            hits_per_page => $self->hits_per_page,
            next_page     => $self->next_page,
            prev_page     => $self->prev_page,
            page          => $self->page,
            pages         => $self->pages,
            query_time    => $self->query_time,
        }
    }

    if ($struct eq 'facets') {
        return $self->facets;
    }

    if ($struct eq 'facet') {
        return $self->facet;
    }

    if ($struct eq 'docs') {
        my $set = [];
        foreach my $doc (@{$self->docs}) {
            push(@{$set}, $doc->record->api);
        }
        return $set;
    }

    return {};
}


__PACKAGE__->meta->make_immutable;
