package CIHM::Access::Content;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef Str Int/;
use Hash::MoreUtils qw/slice_def/;
use Digest::SHA qw/sha1_hex/;
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

has 'filename' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'format' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'derivative_config' => (
	is => 'ro',
	isa => HashRef,
	required => 1
);

sub download {
	my ($self, $download) = @_;
	my $data = {
		expires => _request_expiration(),
		file => $download,
		key => $self->key,
		password => $self->password
	};
	$data->{signature} = _request_signature($data);
	my %query_params = slice_def($data, qw/expires signature key file portalid userid institutionid sessionid sessioncount/);
    return _request_uri($self->server, $data->{file}, \%query_params);
}

sub derivative {
	my ($self, $master, $size, $rotate) = @_;
	my $size_str = $self->derivative_config->{size}{$size} || $self->derivative_config->{default_size};
	my $rotate_angle = $self->derivative_config->{rotate}{$rotate} || 0;
	my $data = {
		expires => _request_expiration(),
		file => $self->filename,
		key => $self->key,
		password => $self->password,
		from => $master,
		format => $self->format,
		size => $size_str,
		rotate => $rotate_angle
	};
	$data->{signature} = _request_signature($data);
	my %query_params = slice_def($data, qw/expires signature key from format size rotate portalid userid institutionid sessionid sessioncount/);
    return _request_uri($self->server, $data->{file}, \%query_params);
}

sub _request_expiration {
    my $time = time() + 90000; # 25 hours in the future
    $time = $time - ($time % 86400); # normalize the expiry time to the closest 24 hour period
    return $time; # minimum 1 hour from now, maximum 25
}

sub _request_signature {
	my ($signature_data) = @_;
    my @keys = qw/password file expires from size rotate portalid userid institutionid sessionid sessioncount/;
    return sha1_hex(join("\n", map { defined($_) ? $_ : '' } @{$signature_data}{@keys}));
}

sub _request_uri {
	my ($content_url, $filename, $params) = @_;
    my $uri = URI->new(join("/", ($content_url, $filename)));
    $uri->query_form($params);
    return $uri->as_string;
}

1;