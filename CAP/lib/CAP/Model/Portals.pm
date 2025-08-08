package CAP::Model::Portals;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef ArrayRef Str/;
use File::Spec::Functions qw/catfile/;
use File::Slurp qw/read_file/;
use JSON qw/decode_json/;
use Scalar::Util qw/blessed/;

use CAP::Portal;

extends 'Catalyst::Model';

has 'path' => (
  is => 'ro',
  isa => 'Str',
  required => 1
);

has '_portals' => (
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
  init_arg => undef
);

has '_subdomains' => (
  is       => 'ro',
  isa      => 'HashRef[Str]',
  default  => sub { {} },
  init_arg => undef
);

sub BUILD {
  my ( $self, $args ) = @_;

  foreach my $filename (glob catfile($self->path, '*.json')) {
    my $file = read_file($filename);
    my $obj = decode_json($file);
    $self->_portals->{$obj->{id}} = CAP::Portal->new($obj);
    
    foreach my $subd (@{ $obj->{subdomains} }) {
      $self->_subdomains->{$subd} = $obj->{id};
    }
  }
  #use Data::Dumper;
  #warn "Portals: " . Dumper($self->_portals);
}

sub portal_from_host {
  my ( $self, $host ) = @_;

  return if (! defined $host);
  
  my $subd = substr( $host, 0, index( $host, '.' ) );
  if ( index( $subd, '-' ) > -1 ) {
    $subd = substr( $subd, 0, index( $subd, '-' ) );
  }

  if( exists($self->_subdomains->{$subd}) ) {
    return $self->_portals->{$self->_subdomains->{$subd}};
  }
}

1;
