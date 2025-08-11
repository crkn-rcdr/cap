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

use Data::Dumper;

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

  my @files = glob catfile($self->path, '*.json');
  warn "Portal JSON files found: " . Dumper(\@files);

  foreach my $filename (@files) {
    my $file = read_file($filename);
    my $obj = decode_json($file);
    $self->_portals->{$obj->{id}} = CAP::Portal->new($obj);
    
    foreach my $subd (@{ $obj->{subdomains} }) {
      $self->_subdomains->{$subd} = $obj->{id};
    }
  }

  #warn "Portals loaded: " . Dumper($self->_portals);
  #warn "Subdomains loaded: " . Dumper($self->_subdomains);
  #use Data::Dumper;
  #warn "Portals: " . Dumper($self->_portals);
}

sub portal_from_host {
  my ( $self, $host ) = @_;

  return if (! defined $host);
  warn "Hosts: " . Dumper($host);
  return $self->_portals->{"online"};
}

1;
