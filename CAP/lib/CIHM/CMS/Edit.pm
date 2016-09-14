package CIHM::CMS::Edit;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/Str Bool ArrayRef HashRef/;
use CIHM::CMS::Edit::LanguageRecord;
use MIME::Base64 qw/decode_base64/;
use DateTime;
use DateTime::Format::ISO8601;

has 'id' => (
	is => 'ro',
	isa => Str,
	default => sub { '' }
);

has 'rev' => (
	is => 'ro',
	isa => Str,
	default => sub { '' }
);

has [qw/block records/] => (
	is => 'ro',
	isa => HashRef,
	default => sub { {} }
);

has 'created' => (
	is => 'ro',
	default => sub { DateTime->now }
);

has 'publish' => (
	is => 'ro',
	isa => Bool,
	default => sub { 0 }
);

has 'portal' => (
	is => 'ro',
	isa => ArrayRef[Str],
	default => sub { [] }
);

has 'aliases' => (
	is => 'ro',
	isa => ArrayRef[Str],
	default => sub { [] }
);

around BUILDARGS => sub {
	my ($orig, $class, $doc, $languages) = @_;

	my $records = {};
	foreach my $l (keys %$languages) {
		$records->{$l} = CIHM::CMS::Edit::LanguageRecord->new(delete $doc->{$l} || {});
		$records->{$l}->{markdown} = decode_base64($doc->{_attachments}{"$l.md"}{data}) if defined $doc->{_attachments}{"$l.md"};
		$records->{$l}->{html} = decode_base64($doc->{_attachments}{"$l.html"}{data}) if defined $doc->{_attachments}{"$l.html"};
	}

	return $class->$orig({
		id => delete $doc->{_id} || '',
		rev => delete $doc->{_rev} || '',
		records => $records,
		%$doc,
	});
};

1;