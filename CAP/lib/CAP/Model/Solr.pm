package CAP::Model::Solr;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
extends 'Catalyst::Model';

use CAP::Solr::Document;
use CAP::Solr::Search;

has 'server'  => (is => 'ro', isa => 'Str', default => 'http://localhost:8983/solr', required => 1);
has 'options' => (is => 'ro', isa => 'Hashref');

method BUILD {
    $self->{options} = {
        'facet'          => 'true',
        'facet.field'    => [ qw( lang media contributor ) ],
        'facet.limit'    => -1,
        'facet.mincount' => 1,
        'facet.sort'     => 'true',
        'fl'             => 'key,type,contributor,label,pkey,plabel,seq,pubmin,pubmax,lang,media,set,collection,pg_label,ti,au,su,pu,no,de,ab,' .
                            'canonicalUri,canonicalMaster,canonicalMasterSize,canonicalMasterMime,canonicalMasterMD5,canonicalDownload,' .
                            'canonicalDownloadSize,canonicalDownloadMime,canonicalDownloadMD5',
        'rows'           => 10,
        'sort'           => 'score desc',
        'start'          => 0,
        'wt'             => 'json',
        'version'        => '2.2'
    };
}

method document (Str $key) {
    my $doc;
    eval { $doc = new CAP::Solr::Document({ key => $key, server => $self->server, options => $self->options }) };
    if ($@) { warn $@; return undef; }
    return $doc;
}

method search {
    my $search;
    eval { $search = new CAP::Solr::Search({ server => $self->server, options => $self->options }) };
    if ($@) { warn $@; return undef; }
    return $search;
}

1;
