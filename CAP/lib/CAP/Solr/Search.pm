package CAP::Solr::Search;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
use WebService::Solr;
use CAP::Solr::ResultSet;

# Properties from parameters passed to the constructor
has 'server'     => (is => 'ro', isa => 'Str', required => 1);
has 'options'    => (is => 'ro', isa => 'HashRef', default => sub{{}});

has 'resultset'  => (is => 'ro', isa => 'CAP::Solr::ResultSet');

has 'solr_q'     => (is => 'rw', isa => 'Str', default => "");

sub BUILD {
}

method query (Str $query, Int :$noescape = 0) {
    if ($noescape) {
        warn "LITERAL QUERY";
        $self->{solr_q} = $query;
    }
    else {
        warn "ESCAPING QUERY";
        $self->{solr_q} = $query;
    }
}

method run {
    my $solr     = new WebService::Solr($self->server);
    my $response = $solr->search($self->solr_q, $self->options);
    $self->{resultset} = new CAP::Solr::ResultSet({ response => $response});
}

method struct (Str $struct) {
    if ($struct eq 'result') {
        return {
            hits          => $self->resultset->hits,
            hits_from     => $self->resultset->hits_from,
            hits_to       => $self->resultset->hits_to,
            hits_per_page => $self->resultset->hits_per_page,
            next_page     => $self->resultset->next_page,
            prev_page     => $self->resultset->prev_page,
            page          => $self->resultset->page,
            pages         => $self->resultset->pages,
            query_time    => $self->resultset->query_time,
        };
    }
    return {};
}

__PACKAGE__->meta->make_immutable;

