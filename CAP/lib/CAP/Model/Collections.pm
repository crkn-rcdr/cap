package CAP::Model::Collections;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef ArrayRef Str/;
use Scalar::Util qw/blessed/;

use CAP::Collection;
use CAP::Portal;

with 'Role::REST::Client';

extends 'Catalyst::Model';

has '+type' => ( default => 'application/json' );

has '+persistent_headers' =>
  ( default => sub { return { Accept => 'application/json' }; } );

has '_collections' => (
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
  init_arg => undef
);

has '_subdomains' => (
  is       => 'ro',
  isa      => 'HashRef',
  default  => sub { {} },
  init_arg => undef
);

sub BUILD {
  my ( $self, $args ) = @_;
  my $response = $self->get( '/_all_docs', { include_docs => 'true' } );
  if ( $response->failed ) {
    my $error = $response->error;
    die "Collections could not be loaded: $error";
  }

  my $rows = $response->data->{rows};
  my $conf = $args->{portal_config};

  my %subdomains;
  my $subcollections = {};
  foreach my $r (@$rows) {
    my $id  = $r->{id};
    my $doc = $r->{doc};
    if ( $conf->{$id} ) {
      $self->_collections->{$id} = CAP::Portal->new( {
          id            => $id,
          label         => $doc->{label},
          summary       => $doc->{summary},
          search        => $conf->{$id}->{search} // 1,
          search_schema => $conf->{$id}->{search_schema} // 'default',
          banners       => $conf->{$id}->{banners} // {},
          pages         => $conf->{$id}->{pages} // {},
          redirects     => $conf->{$id}->{redirects} // {},
          font          => $conf->{$id}->{font} // 'Roboto',
          sr_record     => $conf->{$id}->{sr_record} // 1,
          ga_id         => $conf->{$id}->{ga_id} // ''
        }
      );

      for my $subd ( split ',', $conf->{$id}->{subdomains} ) {
        $subdomains{$subd} = $id;
      }

      if ( $conf->{$id}->{subcollections} ) {
        for my $subc ( split ',', $conf->{$id}->{subcollections} ) {
          $subcollections->{$id} //= [];
          push @{ $subcollections->{$id} }, $subc;
        }
      }
    } else {
      $self->_collections->{$id} = CAP::Collection->new( {
          id      => $id,
          label   => $doc->{label},
          summary => $doc->{summary}
        }
      );
    }
  }

  foreach my $id ( keys %$subcollections ) {
    $self->_collections->{$id}->_set_subcollections(
      { map { $_ => $self->_collections->{$_} } @{ $subcollections->{$id} } }
    );
  }

  foreach my $subd ( keys %subdomains ) {
    $self->_subdomains->{$subd} = $self->_collections->{ $subdomains{$subd} };
  }
}

sub portal_from_host {
  my ( $self, $host ) = @_;
  my $subd = substr( $host, 0, index( $host, '.' ) );
  $subd = substr( $subd, 0, index( $subd, '-' ) )
    if ( index( $subd, '-' ) > -1 );
  return $self->_subdomains->{$subd};
}

sub portals_with_titles {
  my ( $self, $lang ) = @_;
  my $result = {};
  foreach my $id ( keys %{ $self->_collections } ) {
    if ( blessed( $self->_collections->{$id} ) eq 'CAP::Portal' ) {
      $result->{$id} = $self->_collections->{$id}->{label}->{$lang};
    }
  }
  return $result;
}

1;
