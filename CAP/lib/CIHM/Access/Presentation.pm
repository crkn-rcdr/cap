package CIHM::Access::Presentation;

use utf8;
use strictures 2;

use Moo;
use Type::Utils qw/class_type/;
use CIHM::Access::Presentation::Document;
with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json'}; }
);

has 'content' => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not a CIHM::Access::Content" unless ref($_[0]) eq 'CIHM::Access::Content';
	},
	required => 1
);

sub fetch {
	my ($self, $key) = @_;

	my $response = $self->get("/$key");
	if ($response->failed) {
		my $error = $response->error;
		die "Presentation lookup of key $key failed: $error";
	} else {
		return CIHM::Access::Presentation::Document->new({ record => $response->data, content => $self->content });
	}
}

1;