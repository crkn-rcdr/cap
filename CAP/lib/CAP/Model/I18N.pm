package CAP::Model::I18N;

use Moose;
use namespace::autoclean;
use utf8;
use JSON qw/decode_json/;
use File::Slurp qw/read_file/;

extends 'Catalyst::Model';

has 'path' => (
  is       => 'ro',
  isa      => 'Str',
  required => 1
);

has '_tags' => (
  is     => 'ro',
  isa    => 'HashRef',
  writer => '_set_tags'
);

sub BUILD {
  my ( $self, $args ) = @_;
  my $dir  = $self->path;
  my $tags = {};
  for my $lang (qw/en fr/) {
    my $file = read_file( $dir . "/$lang.json" );
    $tags->{$lang} = decode_json($file);
  }
  $self->_set_tags($tags);
}

sub localize {
  my ( $self, $lang, $tag, @args ) = @_;
  my $loc = $self->_tags->{$lang}->{$tag} // $tag;
  for my $i ( 1 .. scalar @args ) {
    my $v = $args[$i - 1];
    $loc =~ s/\%$i/$v/g;
  }
  return $loc;
}

1;