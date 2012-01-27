package CAP::Solr::Record;
use strict;
use warnings;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use List::MoreUtils qw(firstidx);
use namespace::autoclean;

enum 'RecordType' => qw( page document series );

has 'key'         => (is => 'ro', isa => 'Str', required => 1);
has 'type'        => (is => 'ro', isa => 'RecordType', required => 1);
has 'contributor' => (is => 'ro', isa => 'Str', required => 1);
has 'label'       => (is => 'ro', isa => 'Str', required => 1);

has 'timestamp'   => (is => 'ro', isa => 'Str');
has 'pkey'        => (is => 'ro', isa => 'Str');
has 'plabel'      => (is => 'ro', isa => 'Str');
has 'seq'         => (is => 'ro', isa => 'Int');
has 'pubmin'      => (is => 'ro', isa => 'Str');
has 'pubmax'      => (is => 'ro', isa => 'Str');
has 'lang'        => (is => 'ro', isa => 'ArrayRef');
has 'media'       => (is => 'ro', isa => 'ArrayRef');
has 'set'         => (is => 'ro', isa => 'ArrayRef');
has 'collection'  => (is => 'ro', isa => 'ArrayRef');
has 'pg_label'    => (is => 'ro', isa => 'ArrayRef');

has 'ti' => (is => 'ro', isa => 'ArrayRef');
has 'au' => (is => 'ro', isa => 'ArrayRef');
has 'pu' => (is => 'ro', isa => 'ArrayRef');
has 'su' => (is => 'ro', isa => 'ArrayRef');
has 'no' => (is => 'ro', isa => 'ArrayRef');
has 'de' => (is => 'ro', isa => 'ArrayRef');
has 'ab' => (is => 'ro', isa => 'ArrayRef');
has 'tx' => (is => 'ro', isa => 'ArrayRef');

has 'canonicalUri'          => (is => 'ro', isa => 'Str', required => 1);
has 'canonicalMaster'       => (is => 'ro', isa => 'Str');
has 'canonicalMasterSize'   => (is => 'ro', isa => 'Str');
has 'canonicalMasterMime'   => (is => 'ro', isa => 'Str');
has 'canonicalMasterMD5'    => (is => 'ro', isa => 'Str');
has 'canonicalDownload'     => (is => 'ro', isa => 'Str');
has 'canonicalDownloadSize' => (is => 'ro', isa => 'Str');
has 'canonicalDownloadMime' => (is => 'ro', isa => 'Str');
has 'canonicalDownloadMD5'  => (is => 'ro', isa => 'Str');
has 'canonicalPreviewUri'   => (is => 'ro', isa => 'Str');

has '_fl' => (is => 'ro', isa => 'ArrayRef', default => sub{[]}, documentation => 'A list of fields in the record');

around BUILDARGS => sub {
    my $super = shift;
    my $class = shift;
    my $doc   = shift;

    # These are multi-valued fields and must be returned in list form.
    my %multival = map { $_ => 1 } (qw( lang media set collection pg_label ti au pu su no de ab tx ));

    # Collect the names of all the fields in the record.
    my $_fl      = [];
    my %fields   = ( '_fl' => $_fl );

    foreach my $field ($doc->field_names) {
        push(@{$_fl}, $field);
        if ($multival{$field}) {
            $fields{$field} = [$doc->values_for($field)];
        }
        else {
            $fields{$field} = $doc->value_for($field);
        }
    }

    return $class->$super(%fields);
    
};

method api {
    my $fl = {};
    $fl->{key}      = $self->key   if ($self->key);
    $fl->{pkey}     = $self->pkey  if ($self->pkey);
    $fl->{label}    = $self->label if ($self->label);
    $fl->{contributor}    = $self->contributor if ($self->contributor);
    $fl->{collection} = $self->collection if ($self->collection);
    $fl->{type}     = $self->type  if ($self->type);
    $fl->{location} = $self->canonicalUri if ($self->canonicalUri);
    $fl->{title}    = $self->ti    if ($self->ti);
    $fl->{creator}  = $self->au    if ($self->au);
    $fl->{subject}  = $self->su    if ($self->su);
    $fl->{note}     = $self->no    if ($self->no);
    $fl->{text}     = $self->tx    if ($self->tx);
    $fl->{lang}     = $self->lang  if ($self->lang);
    $fl->{media}     = $self->media  if ($self->media);
    return $fl;
}

method first_page {
    if ($self->type ne 'document') {
        warn "Calling CAP::Solr::Record::first_page() on something that isn't a document";
        return 1;
    }

    my @chunk = @{ $self->pg_label }[0..10];

    # this makes the warnings shut up, since there is no $_ to begin with
    $_ = '';

    my $cover_seq = (firstidx { $_ =~ m/cover/i } @chunk) + 1;
    return $cover_seq if $cover_seq > 0;

    my $title_seq = (firstidx { $_ =~ m/title page/i } @chunk) + 1;
    return $title_seq if $title_seq > 0;

    my $toc_seq = (firstidx { $_ =~ m/table of contents/i } @chunk) + 1;
    return $toc_seq if $toc_seq > 0;

    my $page_seq = (firstidx { $_ =~ m/p\./i } @chunk) + 1;
    return $page_seq if $page_seq > 0;

    # I have no idea what the first page is!
    return 1;
}


__PACKAGE__->meta->make_immutable;
