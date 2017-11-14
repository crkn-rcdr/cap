package CIHM::Access::Download;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use Crypt::JWT qw/encode_jwt/;
use URI;

has 'server' => (
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

sub uri {
	my ($self, $download) = @_;
	my ($filename) = $download =~ /.*\/(.*)/;
	my $token = encode_jwt(
		payload => { iss => $self->key, files => "$filename\$" },
		alg => 'HS256',
		key => $self->password,
		auto_iat => 1,
		relative_exp => 86400 # expires in a day
	);
	my $uri = URI->new(join('/', $self->server, $download));
	$uri->query_form({ token => $token });
	return $uri->as_string;
}

1;
