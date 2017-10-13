package CAP::Model::Collections;

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
	writer => '_set_collections' );

sub BUILD {
	my ($self, $args) = @_;
	my $filename = $self->path;
	my $file = read_file($filename);
	my $json = decode_json($file);
	$self->_set_collections($json);
}

sub sorted_keys {
	my ($self, $lang, $portal) = @_;
	my %cs = %{ $self->all->{$portal} };
	return sort { $cs{$a}->{$lang}->{title} cmp $cs{$b}->{$lang}->{title} } keys %cs;
}

sub as_labels {
	my ($self, $lang, $portal) = @_;
	my %cs = %{ $self->all->{$portal} };
	return { map { $_ => $cs{$_}->{$lang}->{title} } keys %cs };
}

1;