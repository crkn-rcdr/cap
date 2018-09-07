package CAP::Model::Collections;

use utf8;
use strictures 2;
use Moose;
use namespace::autoclean;
use Types::Standard qw/HashRef ArrayRef Str/;

with 'Role::REST::Client';

extends 'Catalyst::Model';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json'}; }
);

has 'subcollections' => (
	is => 'ro',
	required => 1
);

has 'all' => (
	is => 'ro',
	isa => 'HashRef',
	writer => '_set_collections'
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
	} else {
		my $collections = { map {
			($_->{id} => $_->{doc} )
		} @{ $response->data->{rows} } };
		$self->_set_collections($collections);
	}
}

sub has_subcollections {
	my ($self, $portal) = @_;
	return !!$self->subcollections->{$portal};
}

sub of_portal {
	my ($self, $portal) = @_;
	my $subs = $self->subcollections->{$portal};
	if ($subs) {
		return { map { ($_ => $self->all->{$_}) } @$subs };
	} else {
		return {};
	}
}

sub sorted_keys {
	my ($self, $lang, $portal) = @_;
	my $labels = $self->as_labels($lang, $portal);
	if ($labels) {
		return [ sort { $labels->{$a} cmp $labels->{$b} } keys %$labels ]
	} else {
		return [];
	}
}

sub as_labels {
	my ($self, $lang, $portal) = @_;
	my @subs = @{ $self->subcollections->{$portal} };
	if (@subs) {
		return { map { $_ => join(' ', @{ $self->all->{$_}->{label}->{$lang} }) } @subs };
	} else {
		return {};
	}
}

1;
