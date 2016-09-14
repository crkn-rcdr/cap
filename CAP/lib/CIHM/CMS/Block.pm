package CIHM::CMS::Block;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/Str Bool ArrayRef HashRef/;
use DateTime;

has [qw/block/] => (
	is => 'ro',
	isa => HashRef,
	default => sub { {} }
);

has [qw/created changed/] => (
	is => 'ro',
	default => sub { DateTime->now }
);

has 'publish' => (
	is => 'ro',
	isa => Bool,
	default => sub { 1 }
);

has 'portal' => (
	is => 'ro',
	isa => ArrayRef[Str],
	default => sub { [] }
);

around BUILDARGS => sub {
	my ($orig, $class, $doc) = @_;

	my $actions = $doc->{action} ? [delete $doc->{action}] : [];
	if ($actions->[0] && (substr($actions->[0], 0, 1) ne '/')) {
		$actions->[0] = '/' . $actions->[0];
	}

	return $class->$orig({
		portal => delete $doc->{portal} || [delete $doc->{portal_id}] || [],
		block => { actions => $actions, label => delete $doc->{label} }
	});
};

sub to_hash {
	my ($self) = @_;
	return {
		block => $self->block,
		created => $self->created->iso8601,
		changed => $self->changed->iso8601,
		publish => $self->publish,
		portal => $self->portal
	};
}

1;
