package CIHM::Access::Derivative;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef Str/;
use Crypt::JWT qw/encode_jwt/;
use URI;
use URI::Escape;

has 'endpoint' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'key' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'password' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'cookie_domain' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'config' => (
	is => 'ro',
	isa => HashRef,
	required => 1
);

# params:
# master - component master
# rotate - CAP rotate number
# size - CAP size number
# from_pdf - switch to PDF mode
# download - item canonical download
# page - page/seq number
sub uri {
	my ($self, $params) = @_;
	my $identifier = $params->{from_pdf} ? $params->{download} : $params->{master};
	$params->{size} ||= "";
	my $bound = $self->config->{size}{$params->{size}} || $self->config->{default_size};
	my $size = "!$bound,$bound";
	my $rotate = $self->config->{rotate}{$params->{rotate}} || 0;

	my $uri = URI->new(join('/', $self->endpoint, uri_escape($identifier), 'full', $size, $rotate, 'default.jpg'));
	my $token = encode_jwt(
		payload => { iss => $self->key, 'derivativeFiles' => $identifier, 'maxDimension' => ($bound + 0) },
		alg => 'HS256',
		key => $self->password,
		auto_iat => 1,
		relative_exp => 86400 # expires in a day
	);
	my $query = { token => $token };
	$query->{page} = $params->{page} if $params->{from_pdf};
	$uri->query_form($query);

	return $uri->as_string;
}

sub cookie_token {
	my ($self) = @_;

	return encode_jwt(
		payload => { iss => $self->key },
		alg => 'HS256',
		key => $self->password,
		auto_iat => 1,
		relative_exp => 86400 # expires in a day
	);
}

sub cookie_auth_uri {
	my ($self) = @_;
	return 'http://' . $self->cookie_domain . '/auth?token=' . $self->cookie_token;
}

1;
