package CAP::Solr::ResultSet;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

has response => (is => 'ro', isa => 'WebService::Solr::Response', required => 1);


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
    $self->{hits_to}       = 1 - $self->hits_from + $self->hits_per_page;
    $self->hits_to > $self->hits ? $self->{hits_to} = $self->hits : 0 ;

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

    #pubmin_year
    #pubmin
    #pubmax
    #pubmax_year
}


__PACKAGE__->meta->make_immutable;
