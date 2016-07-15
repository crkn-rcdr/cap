package CIHM::Access::Presentation;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Int/;
use CIHM::Access::Presentation::Document;
with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json'}; }
);

has 'content' => (
	is => 'ro',
	isa => sub {
		die "$_[0] is not a CIHM::Access::Content" unless ref($_[0]) eq 'CIHM::Access::Content';
	},
	required => 1
);

has 'sitemap_node_limit' => (
	is => 'ro',
	isa => Int,
	required => 1
);

# fetch a copresentation document
sub fetch {
	my ($self, $key) = @_;

	my $response = $self->get("/$key");
	if ($response->failed) {
		my $error = $response->error;
		die "Presentation lookup of key $key failed: $error";
	} else {
		return CIHM::Access::Presentation::Document->new({ record => $response->data, content => $self->content });
	}
}

# get the number of titles found in a given collection
sub title_count {
	my ($self, $collection) = @_;
	my $response = $self->get("/_design/tdr/_view/coltitles", {
		startkey => "[\"$collection\"]",
		endkey => "[\"$collection\", {}]",
		reduce => "true"
	});
	if ($response->failed) {
		my $error = $response->error;
		die "Could not get title_count for $collection: $error";
	} else {
		return $response->data->{rows}[0]{value};
	}
}

# get a list of titles found in a given collection, paginated according to sitemap_node_limit
sub title_list {
	my ($self, $collection, $page) = @_;

	my $response = $self->get("/_design/tdr/_view/coltitles", {
		startkey => "[\"$collection\", {}]",
		endkey => "[\"$collection\"]",
		reduce => 'false',
		include_docs => 'false',
		descending => 'true',
		limit => $self->sitemap_node_limit,
		skip => $self->sitemap_node_limit * ($page - 1)
	});
	if ($response->failed) {
		my $error = $response->error;
		die "Could not get title_list for $collection, page $page: $error";
	} else {
		return [ map {
			{ key => $_->{id}, updated => $_->{key}[1] }
		} @{$response->data->{rows}} ];
	}
}

1;
