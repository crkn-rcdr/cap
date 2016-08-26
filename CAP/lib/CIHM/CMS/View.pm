package CIHM::CMS::View;

use strictures 2;
use Moo;
use Types::Standard qw/Str/;

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

	return undef unless ($body && $doc->{publish});

	return $class->$orig({
		title => $doc->{$lang}{title},
		body => $body
	});
};

1;