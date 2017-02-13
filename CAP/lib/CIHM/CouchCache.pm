package CIHM::CouchCache;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/HashRef ArrayRef Str Int Enum InstanceOf/;
use DateTime;
use DateTime::Format::ISO8601;

with 'Role::REST::Client';

has '+type' => (
	isa => Enum[qw{application/json text/html text/plain application/x-www-form-urlencoded}],
	default => sub { 'application/json' }
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

# in seconds
has 'interval' => (
	is => 'ro',
	isa => Int,
	required => 1
);

has '_cache' => (
	is => 'ro',
	isa => HashRef[HashRef],
	default => sub { {} }
);

has '_checks' => (
	is => 'ro',
	isa => HashRef[InstanceOf['DateTime']],
	default => sub { {} }
);

sub register {
	my ($self, $cache_key) = @_;
	$self->_cache->{$cache_key} = {};
	$self->_checks->{$cache_key} = DateTime->now()->subtract(seconds => $self->interval);
	return;
}

sub fetch {
	my ($self, $cache_key, $key, $value_code) = @_;
	$self->_invalidate($cache_key);

	# in case you forget, //= is defined ? thing : new thing
	$self->_cache->{$cache_key}->{$key} //= &$value_code;

	return $self->_cache->{$cache_key}->{$key};
}

sub _invalidate {
	my ($self, $cache_key) = @_;

	if ($self->_checks->{$cache_key} < DateTime->now()->subtract(seconds => $self->interval)) {
		my $doc = $self->get("/$cache_key")->data;
		my $valid_as_of = $doc->{valid} ? DateTime::Format::ISO8601->parse_datetime($doc->{valid}) : DateTime->now();
		if ($valid_as_of > $self->_checks->{$cache_key}) {
			$self->_cache->{$cache_key} = {};
		}
		$self->_checks->{$cache_key} = DateTime->now();
	}
}

sub revalidate {
	my ($self, $cache_key) = @_;
	my $url = "/$cache_key";
	my $doc = $self->get($url)->data;
	my $rev = $doc->{_rev};
	$self->set_header('If-Match' => $rev) if ($rev);

	my $response = $self->put($url, { valid => DateTime->now()->iso8601() });

	if ($response->error) {
		use Data::Dumper; my $error = Dumper $response;
		warn "cms database error: $error while revalidating cache $cache_key";
	}

	return;
}

1;
