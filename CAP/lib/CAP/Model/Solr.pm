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
use CAP::Solr::Query;

has 'server'        => (is => 'ro', isa => 'Str', default => 'http://localhost:8983/solr', required => 1);
has 'options'       => (is => 'ro', isa => 'HashRef');
has 'fields'        => (is => 'ro', isa => 'HashRef');
has 'types'         => (is => 'ro', isa => 'HashRef');
has 'sorting'       => (is => 'ro', isa => 'HashRef');
has 'default_field' => (is => 'ro', isa => 'HashRef');

method BUILD {
    # Default options to pass to Solr
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

    # Templates for expanding field parameter queries to Solr queries. The
    # canonical parameter is the one that others should be maped to. E.g.
    # su=foo should be remapped to q=su:foo
    $self->{fields} = {
        q =>           { type => 'text',   template => 'au:% OR ti:% OR su:% OR no:% OR pu:% OR ab:% OR tx:%', canonical => 1 },
        contributor => { type => 'string', template => 'contributor: %' },
        key =>         { type => 'string', template => 'key: %' },
        lang =>        { type => 'string', template => 'lang: %' },
        media =>       { type => 'string', template => 'media: %' },
        pkey =>        { type => 'string', template => 'pkey: %' },
        set =>         { type => 'string', template => 'set: %' },
        au =>          { type => 'text',   template => 'au:%' },
        ti =>          { type => 'text',   template => 'ti:%' },
        su =>          { type => 'text',   template => 'su:%' },
        tx =>          { type => 'text',   template => 'tx:%' },
        no =>          { type => 'text',   template => 'ab:% OR no:%' },

    };

    # Query fragments for limiting by record type
    $self->{types} = {
        default  => 'type:(series OR document)',
        any      => '',
        page     => 'type:page',
        document => 'type:document',
        series   => 'type:series',
    };

    $self->{sorting} = {
        default  => 'score desc',
        oldest   => 'pubmin asc',
        newest   => 'pubmax desc',
        seq      => 'pkey asc, seq asc',
    };

    $self->{default_field} = 'q';
}

method document (Str $key, :$text = 0, :$subset = "") {
    my $doc;
    my %fl = ();
    $fl{fl} = join(",", $self->options->{fl}, "tx") if ($text); # Include the page text
    eval { $doc = new CAP::Solr::Document({ key => $key, subset => $subset, server => $self->server, options => { %{$self->options}, %fl } }) };
    if ($@) { warn $@; return undef; }
    return $doc;
}

method search (Str $subset = "") {
    my $search;
    eval { $search = new CAP::Solr::Search({ server => $self->server, options => $self->options, subset => $subset }) };
    if ($@) { return undef; }
    return $search;
}

method query {
    return new CAP::Solr::Query(default_field => $self->default_field, fields => $self->fields, types => $self->types, sorting => $self->sorting);
}

1;
