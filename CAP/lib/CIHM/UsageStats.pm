package CIHM::UsageStats;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/Str Enum/;
use JSON qw/decode_json/;
use List::Util qw/reduce/;

with 'Role::REST::Client';

has '+type' => (
    isa => Enum[qw{application/json}],
    is  => 'ro',
    default => sub { 'application/json' },
);

has [qw/statsdb logfiledb/] => (
	is => 'ro',
	isa => Str,
	required => 1
);

sub BUILD {
	my ($self, $args) = shift;
	$self->set_persistent_header(Accept => 'application/json');
}

sub create_databases {
	my ($self) = @_;
	$self->put($self->statsdb);
	$self->put($self->logfiledb);
}

sub update_or_create {
	my ($self, $key, $stats) = @_;

	my $url = join('/', $self->statsdb, $key);
	my $lookup = $self->get($url);
	if ($lookup->code eq '200') {
		my $doc = $lookup->data;
		delete $doc->{_id};
		$self->set_header('If-Match' => delete $doc->{_rev});
		my $new_doc = $self->_add_stats($doc, $stats);
		$self->put($url, $new_doc);
	} else {
		$self->put($url, $stats);
	}
}

sub _transform_row_for_bulk_update {
	my ($row, $stats) = @_;
	if ($row->{error}) { # going to assume this is not found
		my $key = $row->{key};
		return { '_id' => $key, %{$stats->{$key}} };
	} else {
		my $key = $row->{id};
		return _add_stats($row->{doc}, $stats->{$key});
	}
}

sub _add_stats {
	my ($doc, $stats) = @_;
	foreach (qw/sessions searches views requests/) {
		$doc->{$_} += $stats->{$_};
	}
	return $doc;
}

sub update {
	my ($self, $stats) = @_;

	# look up keys
	my $key_struct = { keys => [keys %$stats] };
	my $lookup_url = join('/', $self->statsdb, '_all_docs?include_docs=true');
	my @rows = @{$self->post($lookup_url, $key_struct)->data->{rows}};

	# transform rows and add stats
	my @transformed_rows = map { _transform_row_for_bulk_update($_, $stats) } @rows;

	# bulk update docs
	my $update_url = join('/', $self->statsdb, '_bulk_docs');
	my $response = $self->post($update_url, { docs => \@transformed_rows })->data;

	return scalar @$response;
}

sub key {
	my ($self, $portal, $year, $month, $type, $subtype) = @_;
	$type //= 'portal';
	$subtype //= '';
	my %codes = (portal => 'p', institution => 'i', user => 'u');
	return "$codes{$type}$subtype-$portal-$year-$month";
}

sub register_logfiles {
	my ($self, $logfiles) = @_;
	my $docs = [map { {'_id' => $_ } } @$logfiles];
	my $post_data = {docs => $docs};
	my $url = join('/', $self->logfiledb, '_bulk_docs');
	my @rows = @{$self->post($url, $post_data)->data};
	return map { [$_->{id}, $_->{error} ? 1 : 0] } @rows;
}


1;
