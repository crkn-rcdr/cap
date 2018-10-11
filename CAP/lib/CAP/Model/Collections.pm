package CAP::Model::Collections;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef ArrayRef Str/;

use CAP::Collection;
use CAP::Portal;

with 'Role::REST::Client';

extends 'Catalyst::Model';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json'}; }
);

has '_collections' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
	init_arg => undef
);

has '_subdomains' => (
	is => 'ro',
	isa => 'HashRef',
	default => sub { {} },
	init_arg => undef
);

sub COMPONENT {
	my ($class, $app, $args) = @_;
	my $config = { server => $app->config->{services}->{collection}->{endpoint} };
	$args = $class->merge_config_hashes($config, $args);

	return $class->new($app, $args);
}

sub BUILD {
	my ($self, $args) = @_;
	my $response = $self->get('/_all_docs', { include_docs => 'true' });
	if ($response->failed) {
		my $error = $response->error;
		die "Collections could not be loaded: $error";
	}

	my $rows = $response->data->{rows};
	my $conf = $args->{portal_config};

	my %subdomains;
	my $subcollections = {};
	foreach my $r (@$rows) {
		my $id = $r->{id};
		my $doc = $r->{doc};
		if ($conf->{$id}) {
			$self->_collections->{$id} = CAP::Portal->new({
				id => $id,
				label => $doc->{label},
				summary => $doc->{summary},
				search => $conf->{$id}->{search} // 1
			});

			for my $subd (split ',', $conf->{$id}->{subdomains}) {
				$subdomains{$subd} = $id;
			}

			if ($conf->{$id}->{subcollections}) {
				for my $subc (split ',', $conf->{$id}->{subcollections}) {
					$subcollections->{$id} //= [];
					push @{ $subcollections->{$id} }, $subc;
				}
			}
		} else {
			$self->_collections->{$id} = CAP::Collection->new({
				id => $id,
				label => $doc->{label},
				summary => $doc->{summary}
			});
		}
	}

	foreach my $id (keys %$subcollections) {
		$self->_collections->{$id}->_set_subcollections({ map {
			$_ => $self->_collections->{$_}
		} @{ $subcollections->{$id} } });
	}

	foreach my $subd (keys %subdomains) {
		$self->_subdomains->{$subd} = $self->_collections->{$subdomains{$subd}};
	}
}

sub portal_from_host {
	my ($self, $host) = @_;
	my $subd = substr($host, 0, index($host, '.'));
	return $self->_subdomains->{$subd};
}

1;
