package CAP::Model::ParlSession;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef/;
use JSON qw/decode_json/;
use File::Slurp qw/read_file/;

extends 'Catalyst::Model';

has 'path' => (
	is => 'ro',
	isa => 'Str',
	required => 1 );

has '_sessions' => (
	is => 'ro',
	isa => 'HashRef',
	writer => '_set_sessions' );

sub BUILD {
  my ($self, $args) = @_;
  my $file = read_file($self->path);
  my $json = decode_json($file);
  $self->_set_sessions($json);
}

sub session {
  my ($self, $session) = @_;

  return $self->_sessions->{$session};
}

sub all {
  my ($self) = @_;
  
  return $self->_sessions;
}

1;