package CIHM::Swift::Client;

=encoding utf8

=head1 NAME

CIHM::Swift::Client - Client for accessing OpenStack Swift installations

=cut

use strictures 2;

use Carp;
use Moo;
use Types::Standard qw/Str HashRef InstanceOf/;
use Furl;
use MIME::Types;
use URI;

use CIHM::Swift::Client::Response;

has 'server' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'user' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'password' => (
  is       => 'ro',
  isa      => Str,
  required => 1
);

has 'account' => (
  is      => 'lazy',
  isa     => Str,
  default => sub { return 'AUTH_' . shift->user; }
);

has 'furl_options' => (
  is      => 'ro',
  isa     => HashRef,
  default => sub { return {}; }
);

has '_agent' => (
  is      => 'lazy',
  isa     => InstanceOf ['Furl'],
  default => sub { return Furl->new( %{ shift->furl_options } ); },
);

has '_mt' => (
  is      => 'ro',
  isa     => InstanceOf ['MIME::Types'],
  default => sub { return MIME::Types->new; }
);

has '_token' => (
  is      => 'rwp',
  isa     => Str,
  default => ''
);

sub _uri {
  return URI->new( join '/', shift->server, 'v1', grep( defined, @_ ) );
}

sub _authorize {
  my ($self) = @_;

  if ( $self->_token eq '' ) {
    my $response;

    # SwiftStack might not be initialized yet, especially in testing mode.
    my $code = 500;
    while ( $code >= 500 ) {
      $response = $self->_agent->get(
        join( '/', $self->server, 'auth', 'v1.0' ),
        [
          'X-Auth-User' => $self->user,
          'X-Auth-Key'  => $self->password
        ]
      );
      $code = $response->code;
      if ( $code >= 500 ) {
        warn "Error during Swift authorization: code=$code message="
          . $response->message . "\n";
        sleep(1);
      }
    }

    if ( $code < 300 ) {
      $self->_set__token( $response->header('X-Auth-Token') );
    } else {
      croak "SwiftStack authorization failure: $code";
    }
  }

  return [ 'X-Auth-Token' => $self->_token ];
}

sub info {
  my ($self) = @_;

  my $response = CIHM::Swift::Client::Response->new(
    {
      basis       => $self->_agent->get( $self->server . '/info', $self->_authorize ),
      deserialize => 'application/json'
    }
  );

  if ( $response->code == 401 ) {
    $self->_set__token('');
    return $self->info();
  }

  return $response;
}

sub _request {
  my ( $self, $method, $options, $container, $object ) = @_;
  $method = uc $method;
  $options ||= {};
  my $uri = $self->_uri( $self->account, $container, $object );
  my $headers = $self->_authorize;
  my $content;
  my $deserialize = $options->{deserialize};

  if ( $options->{query} ) {
    $uri->query_form( $options->{query} );
  }

  if ( $options->{headers} ) {
    $headers = [ @$headers, @{ $options->{headers} } ];
  }

  if ( $options->{content} ) {
    my $mime = $self->_mt->mimeTypeOf($object);
    my $mime_type = $mime ? $mime->type : 'application/octet-stream';
    $content = $options->{content};
    $headers = [ @$headers, 'Content-Type' => $mime_type ];
  }

  if ( $options->{json} ) {
    $headers = [ @$headers, 'Accept' => 'application/json' ];
    $deserialize = 'application/json';
  }

  my $response = CIHM::Swift::Client::Response->new(
    {
      basis => $self->_agent->request(
        method     => $method,
        url        => $uri->as_string,
        headers    => $headers,
        content    => $content,
        write_file => $options->{write_file}
      ),
      deserialize => $deserialize
    }
  );

  if ( $response->code == 401 ) {
    $self->_set__token('');
    return $self->_request( $method, $options, $container, $object );
  }

  return $response;
}

sub _metadata_headers {
  my ( $metadata, $prefix ) = @_;
  return [ map { $prefix . $_ => $metadata->{$_} } keys %$metadata ];
}

sub _list_options {
  my ($q) = @_;
  $q ||= {};
  return { map { $q->{$_} ? ( $_, $q->{$_} ) : () }
      qw/limit marker end_marker prefix delimiter/ };
}

sub account_head { return shift->_request('head'); }

sub account_get {
  my ( $self, $query_options ) = @_;
  return $self->_request( 'get',
    { json => 1, query => _list_options($query_options) } );
}

sub account_post {
  my ( $self, $metadata ) = @_;
  croak 'Making a POST request to an account without metadata'
    unless $metadata;
  return $self->_request( 'post',
    { headers => _metadata_headers( $metadata, 'X-Account-Meta-' ) } );
}

sub _container_request {
  my ( $self, $method, $options, $container ) = @_;
  croak 'cannot make container request without container name'
    unless $container;
  return $self->_request( $method, $options, $container );
}

sub container_put {
  my ( $self, $container, $metadata ) = @_;
  my $options = {};
  if ( $metadata && ref $metadata eq 'HASH' ) {
    $options->{headers} = _metadata_headers( $metadata, 'X-Container-Meta-' );
  }
  return $self->_container_request( 'put', $options, $container );
}

sub container_head { return shift->_container_request( 'head', {}, shift ); }

sub container_get {
  my ( $self, $container, $query_options ) = @_;
  return $self->_container_request( 'get',
    { json => 1, query => _list_options($query_options) }, $container );
}

sub container_post {
  my ( $self, $container, $metadata ) = @_;
  croak 'Making a POST request to an object without metadata'
    unless $metadata;
  return $self->_container_request( 'post',
    { headers => _metadata_headers( $metadata, 'X-Container-Meta-' ) },
    $container );
}

sub container_delete {
  return shift->_container_request( 'delete', {}, shift );
}

sub _object_request {
  my ( $self, $method, $options, $container, $object ) = @_;
  croak 'cannot make object request without container name'
    unless $container;
  croak 'cannot make object request without object name' unless $object;
  return $self->_request( $method, $options, $container, $object );
}

sub object_put {
  my ( $self, $container, $object, $content, $metadata ) = @_;
  croak 'cannot put object without string/filehandle' unless $content;
  my $options = { content => $content };
  if ( $metadata && ref $metadata eq 'HASH' ) {
    $options->{headers} = _metadata_headers( $metadata, 'X-Object-Meta-' );
  }
  return $self->_object_request( 'put', $options, $container, $object );
}

sub object_head {
  return shift->_object_request( 'head', {}, shift, shift );
}

sub object_get {
  my ( $self, $container, $object, $options ) = @_;
  $options ||= {};
  $options = {
    deserialize => $options->{deserialize},
    write_file  => $options->{write_file}
  };
  return $self->_object_request( 'get', $options, $container, $object );
}

sub object_post {
  my ( $self, $container, $object, $metadata ) = @_;
  croak 'Making a POST request to an object without metadata'
    unless $metadata;
  return $self->_object_request( 'post',
    { headers => _metadata_headers( $metadata, 'X-Object-Meta-' ) },
    $container, $object );
}

sub object_delete {
  return shift->_object_request( 'delete', {}, shift, shift );
}

sub object_copy {
  my ( $self, $sourcecontainer, $sourceobject, $destinationcontainer,
    $destinationobject )
    = @_;

  my $dest = join '/', $destinationcontainer, $destinationobject;

  return $self->_object_request( 'copy',
    { headers => [ 'Destination' => $dest ] },
    $sourcecontainer, $sourceobject );
}

1;
