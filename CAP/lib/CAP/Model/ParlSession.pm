package CAP::Model::ParlSession;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef/;

extends 'Catalyst::Model';
with 'Role::REST::Client';

has '+type' => (
	default => sub { 'application/json' }
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

has '_sessions' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
	init_arg => undef
);

sub BUILD {
  my ($self, $args) = @_;
  my $response = $self->get('/_all_docs', { include_docs => 'true' });
	if ($response->failed) {
		my $error = $response->error;
		die "Parliament sessions could not be loaded: $error";
	}

  foreach my $row (@{ $response->data->{rows} }) {
    $self->_sessions->{$row->{id}} = $row->{doc};
  }
}

sub session {
  my ($self, $session) = @_;

  return $self->_sessions->{$session} || {};
}

sub all {
  my ($self) = @_;
  
  return $self->_sessions;
}

1;