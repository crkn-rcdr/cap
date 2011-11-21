package CAP::Model::Solr;

use strict;
use warnings;
use Moose;
extends 'Catalyst::Model';

use CAP::Solr::Document;
use CAP::Solr::ResultSet;

has 'server'  => (is => 'ro', isa => 'Str', default => 'http://localhost:8983/solr', required => 1);

sub document {
    my($self, $key) = @_;
    my $doc;
    eval { $doc = new CAP::Solr::Document({ key => $key, server => $self->server }) };
    if ($@) { warn $@; return undef; }
    return undef if ($@);
    return $doc;
}

1;
