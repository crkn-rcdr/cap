package CAP::Model::Depositors;

use Moose;
use namespace::autoclean;
use utf8;
use JSON qw/decode_json/;
use File::Slurp qw/read_file/;

extends 'Catalyst::Model';

has 'path' => (
	is => 'ro',
	isa => 'Str',
	required => 1 );

has 'all' => (
	is => 'ro',
	isa => 'HashRef',
	writer => '_set_depositors' );

sub BUILD {
	my ($self, $args) = @_;
	my $filename = $self->path;
	my $file = read_file($filename);
	my $json = decode_json($file);
	$self->_set_depositors($json);
}

sub as_labels {
	my ($self, $lang) = @_;
	my %cs = %{ $self->all };
	return { map { $_ => $cs{$_}->{$lang} } keys %cs };
}

1;