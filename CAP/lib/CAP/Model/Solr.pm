package CAP::Model::Solr;

use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;
extends 'Catalyst::Model';

use WebService::Solr;
use CAP::Solr::AuthDocument;
use CAP::Solr::Search;
use CAP::Solr::Query;
use CAP::Solr::ResultSet;

has 'server'        => (is => 'ro', isa => 'Str', default => 'http://localhost:8983/solr', required => 1);
has 'interface'     => (is => 'ro', isa => 'WebService::Solr');
has 'options'       => (is => 'ro', isa => 'HashRef');
has 'fields'        => (is => 'ro', isa => 'HashRef');
has 'types'         => (is => 'ro', isa => 'HashRef');
has 'sorting'       => (is => 'ro', isa => 'HashRef');
has 'default_field' => (is => 'ro', isa => 'HashRef');

method BUILD {
    # Default options to pass to Solr
    $self->{options} = {
        'facet'          => 'true',
        'facet.field'    => [ qw( lang media contributor collection ) ],
        'facet.limit'    => -1,
        'facet.mincount' => 1,
        'facet.sort'     => 'true',
        'fl'             => 'key,type,contributor,label,pkey,plabel,seq,pubmin,pubmax,lang,media,set,collection,pg_label,ti,au,su,pu,no,de,ab,' .
                            'canonicalUri,canonicalMaster,canonicalMasterSize,canonicalMasterMime,canonicalMasterMD5,canonicalDownload,' .
                            'canonicalDownloadSize,canonicalDownloadMime,canonicalDownloadMD5,identifier,no_continued,no_continues,' .
                            'no_extent,no_frequency,no_missing,no_rights,no_source,term,portal,cap_id,cap_title_id,timestamp',
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
        q =>           { type => 'text',   template => 'gq:% OR tx:%', canonical => 1 },
        contributor => { type => 'string', template => 'contributor: %' },
        key =>         { type => 'string', template => 'key: %' },
        lang =>        { type => 'string', template => 'lang: %' },
        media =>       { type => 'string', template => 'media: %' },
        collection =>  { type => 'string', template => 'collection: %' },
        pkey =>        { type => 'string', template => 'pkey: %' },
        set =>         { type => 'string', template => 'set: %' },
        identifier =>  { type => 'string', template => 'identifier: %' },
        term =>        { type => 'sint',   template => 'term: %' },
        au =>          { type => 'text',   template => 'au:%' },
        ti =>          { type => 'text',   template => 'ti:%' },
        su =>          { type => 'text',   template => 'su:%' },
        tx =>          { type => 'text',   template => 'tx:%' },
        no =>          { type => 'text',   template => 'ab:% OR no:% OR no_continued:% OR no_continues:% OR no_extent:% OR ' .
                            'no_frequency:% OR no_missing:% OR no_rights:% OR no_source:%'
                       },

    };

    # Query fragments for limiting by record type
    $self->{types} = {
        default   => 'type:(series OR document)',
        any       => '',
        page      => 'type:page',
        document  => 'type:document',
        series    => 'type:series',
        browsable => 'objectClass:browsable',
    };

    $self->{sorting} = {
        default  => 'score desc',
        oldest   => 'pubmin asc',
        newest   => 'pubmax desc',
        seq      => 'pkey asc, seq asc',
    };

    $self->{default_field} = 'q';

    $self->{interface} = new WebService::Solr($self->{server});
}

method document (Str $key, :$text = 0, :$subset = "") {
    my $doc;
    $key =~ s/[^A-Za-z0-9_\.\-]//g; # Strip out characters that are not legal in document IDs
    my %fl = ();
    $fl{fl} = join(",", $self->options->{fl}, "tx") if ($text); # Include the page text
    eval { $doc = new CAP::Solr::AuthDocument({ key => $key, subset => $subset, solr => $self->interface, options => { %{$self->options}, %fl } }) };
    if ($@) { warn $@; return undef; }
    return $doc;
}

method search (HashRef $params = {}, Str $subset = "") {
    my $query = new CAP::Solr::Query(default_field => $self->default_field, fields => $self->fields, types => $self->types);
    my $search = new CAP::Solr::Search({
        solr => $self->interface,
        params => $params,
        options => $self->options,
        sorting => $self->sorting,
        subset => $subset,
        query => $query });
    return $search;
}

method search_document_pages (CAP::Solr::Document $doc, HashRef $params, Str $subset = "", Int $rows = 10, Int $start = 0) {
    my $result = {};
    if (($params->{q} && $params->{q} =~ /\S/) ||
        ($params->{tx} && $params->{tx} =~ /\S/)) {
        if ($doc->type_is('document') && $doc->child_count) {
            my $search_params = { 'q', $params->{q}, 'tx', $params->{tx}, 'pkey', $doc->key, 'so', 'seq', 't', 'page' };
            my $pageset = $self->search($search_params, $subset)->run(options => {
                rows => $rows,
                start => $start,
                fl => 'key,seq,label,pkey,canonicalUri,contributor,type'
            });
            $result = $pageset if ($pageset->hits);
        }
    }
    return $result;
}

method random_document (Str $subset = "") {
    my $searcher = $self->search({ t => 'document' }, $subset);
    my $ndocs = $searcher->count();
    my $index = int(rand() * $ndocs) + 1;
    return $searcher->nth_record($index);
}

method random_page (Str $subset = "") {
    my $searcher = $self->search({ t => 'page' }, $subset);
    my $ndocs = $searcher->count();
    my $index = int(rand() * $ndocs) + 1;
    return $searcher->nth_record($index);
}


1;
