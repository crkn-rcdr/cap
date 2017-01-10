package CIHM::UsageStats;

use utf8;
use strictures 2;
use Moo;
use File::Basename qw/fileparse/;
use Types::Standard qw/Str Enum/;
use JSON qw/decode_json/;

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
		$doc->{$_} += $stats->{$_} // 0;
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
	my ($self, $portal, $year, $month, $type, $id) = @_;
	my $mask = $self->keymask($portal, $type, $id);
	return "$mask-$year-$month";
}

sub keymask {
	my ($self, $portal, $type, $id) = @_;
	$type //= 'portal';
	$id //= '';
	my %codes = (portal => 'p', institution => 'i', user => 'u');
	return "$codes{$type}$id-$portal";
}

sub register_logfiles {
	my ($self, @logfiles) = @_;
	my $docs = [map { {'_id' => (fileparse($_))[0] } } @logfiles];
	my $post_data = {docs => $docs};
	my $url = join('/', $self->logfiledb, '_bulk_docs');
	my @rows = @{$self->post($url, $post_data)->data};
	return map { [$_->{id}, $_->{error} ? 1 : 0] } @rows;
}

sub _transform_doc_for_display {
	my ($doc) = @_;
	my $key = $doc->{_id};
	my ($year, $month) = $key =~ /.+\-.+\-(\d{4})\-(\d{2})/;
	return {
		year => $year,
		month => $month,
		sessions => $doc->{sessions} // 0,
		requests => $doc->{requests} // 0,
		searches => $doc->{searches} // 0,
		views => $doc->{views} // 0
	};
}

sub retrieve {
	my ($self, $portal, $type, $id) = @_;
	my $mask = $self->keymask($portal, $type, $id);

	my $call_args = {
		descending => 'true',
		startkey => "\"$mask.\"",
		endkey => "\"$mask\"",
		include_docs => 'true'
	};

	my $url = join('/', $self->statsdb, '_all_docs');
	my $rows = $self->get($url, $call_args)->data->{rows};

	return [map { _transform_doc_for_display($_->{doc}) } @$rows];
}

1;
