package CIHM::Access::Presentation;

use utf8;
use strictures 2;

use Moo;
with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json'}; }
);

sub fetch {
	my ($self, $key) = @_;

	my $response = $self->get("/$key");
	if ($response->failed) {
		my $error = $response->error;
		die "Presentation lookup of key $key failed: $error";
	} else {
		return $response->data;
	}
}

sub fetch_parent {
	my ($self, $key) = @_;

	my $child = $self->fetch($key);
	if ($child->{pkey}) {
		return $self->fetch($child->{pkey});
	} else {
		die "$key does not have a parent";
	}
}

sub fetch_child {
	my ($self, $key, $seq) = @_;

	my $parent = $self->fetch($key);
	if ($parent->{order} && $parent->{order}[$seq - 1]) {
		return $self->fetch($parent->{order}[$seq - 1]);
	} else {
		die "$key does not have a child with seq: $seq";
	}
}

1;