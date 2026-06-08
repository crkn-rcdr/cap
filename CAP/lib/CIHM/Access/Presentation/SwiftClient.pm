package CIHM::Access::Presentation::SwiftClient;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use Crypt::Mac::HMAC qw/hmac_hex/;
use URI;
use CIHM::Swift::Client;

has 'container_preservation' => (
  is     => 'ro',
  coerce => sub {
    URI->new( $_[0] );
  },
  required => 1
);

has 'container_access' => (
  is     => 'ro',
  coerce => sub {
    URI->new( $_[0] );
  },
  required => 1
);

has 'temp_url_key' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'server' => (
  is      => 'lazy',
  isa     => Str,
  default => sub {
    return _container_parts( shift->container_access )->{server};
  }
);

has 'user' => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_user'
);

has 'password' => (
  is        => 'ro',
  isa       => Str,
  predicate => 'has_password'
);

has 'account' => (
  is      => 'lazy',
  isa     => Str,
  default => sub {
    return _container_parts( shift->container_access )->{account};
  }
);

has 'container_name_preservation' => (
  is      => 'lazy',
  isa     => Str,
  default => sub {
    return _container_parts( shift->container_preservation )->{container};
  }
);

has 'container_name_access' => (
  is      => 'lazy',
  isa     => Str,
  default => sub {
    return _container_parts( shift->container_access )->{container};
  }
);

has '_storage_client' => (
  is      => 'lazy',
  default => sub {
    my ($self) = @_;
    die "Swift user/password are not configured for server-side downloads\n"
      unless $self->has_storage_credentials;

    return CIHM::Swift::Client->new(
      server       => $self->server,
      user         => $self->user,
      password     => $self->password,
      account      => $self->account,
      furl_options => { timeout => 3600 }
    );
  }
);

# Returns a Swift TempURL for the preservation file at $obj_path.
sub preservation_uri {
  my ($self, $obj_path) = @_;
  return $self->_uri($self->container_preservation, $obj_path);
}

# Returns a Swift TempURL for the access file at $obj_path.
sub access_uri {
  my ($self, $obj_path, $filename) = @_;
  return $self->_uri($self->container_access, $obj_path, $filename);
}

sub download_uri {
  my ( $self, $key, $seq ) = @_;
  return join '/', '/download', map { _escape_path_part($_) }
    grep { defined && length } ( $key, $seq );
}

sub has_storage_credentials {
  my ($self) = @_;
  return $self->has_user && $self->has_password;
}

sub file_size {
  my ( $self, $repository, $obj_path ) = @_;
  return undef unless $self->has_storage_credentials;

  my $response = eval { $self->object_head( $repository, $obj_path ) };
  return undef if ( $@ || !$response || $response->code != 200 );
  return $response->content_length;
}

sub object_head {
  my ( $self, $repository, $obj_path ) = @_;
  return $self->_storage_client->object_head(
    $self->_container_name($repository),
    $obj_path
  );
}

sub object_get {
  my ( $self, $repository, $obj_path, $options ) = @_;
  return $self->_storage_client->object_get(
    $self->_container_name($repository),
    $obj_path,
    $options
  );
}

sub _uri {
  my ( $self, $container, $obj_path, $filename ) = @_;

  my $expires = time + 86400;    # expires in a day
  my $path      = join( '/', $container->path, $obj_path );
  my $payload   = "GET\n$expires\n$path";
  my $signature = hmac_hex( 'SHA1', $self->temp_url_key, $payload );

  my $uri = URI->new( join( '/', $container->as_string, $obj_path ) );

  my $query = { temp_url_sig => $signature, temp_url_expires => $expires };
  
  if (defined $filename) {
    $query->{filename} = $filename;
  }

  $uri->query_form( $query );
  return $uri->as_string;
}

sub _container_name {
  my ( $self, $repository ) = @_;
  return $self->container_name_access if $repository eq 'access';
  return $self->container_name_preservation if $repository eq 'preservation';
  die "Unknown Swift repository: $repository";
}

sub _container_parts {
  my ($uri) = @_;
  my @path = grep { length } split '/', $uri->path;
  die "Could not parse Swift container URL: $uri"
    unless @path >= 3;

  return {
    server    => $uri->scheme . '://' . $uri->authority,
    account   => $path[1],
    container => $path[2]
  };
}

sub _escape_path_part {
  my ($part) = @_;
  $part =~ s/([^A-Za-z0-9\-\._~])/sprintf("%%%02X", ord($1))/eg;
  return $part;
}

1;
