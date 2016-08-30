package CIHM::CMS::View;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/Str/;

has 'id' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'title' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'body' => (
	is => 'ro',
	isa => Str,
	required => 1
);

around BUILDARGS => sub {
	my ($orig, $class, $doc, $body, $lang) = @_;

	return $class->$orig({
		id => $doc->{_id},
		title => $doc->{$lang}{title},
		body => $body
	});
};

1;
