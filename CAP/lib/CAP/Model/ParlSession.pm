package CAP::Model::ParlSession;

use utf8;
use strictures 2;
use Moo;

extends 'Catalyst::Model';
with 'Role::REST::Client';

has '+type' => (
	default => sub { 'application/json' }
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

sub session {
  my ($self, $session) = @_;
  my $response = $self->get("/$session");

  return $response->data || {};
}

1;