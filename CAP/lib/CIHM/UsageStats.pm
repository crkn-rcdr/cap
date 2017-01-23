package CIHM::UsageStats;

use utf8;
use strictures 2;
use Moo;
use File::Basename qw/fileparse/;
use Types::Standard qw/Str Enum/;
use JSON qw/decode_json/;
use List::Util qw/reduce/;

use constant MONTHS => {
	en => {
		'01' => 'January',
		'02' => 'February',
		'03' => 'March',
		'04' => 'April',
		'05' => 'May',
		'06' => 'June',
		'07' => 'July',
		'08' => 'August',
		'09' => 'September',
		'10' => 'October',
		'11' => 'November',
		'12' => 'December',
	},
	fr => {
		'01' => 'janvier',
		'02' => 'février',
		'03' => 'mars',
		'04' => 'avril',
		'05' => 'mai',
		'06' => 'juin',
		'07' => 'juillet',
		'08' => 'août',
		'09' => 'septembre',
		'10' => 'octobre',
		'11' => 'novembre',
		'12' => 'décembre',
	}
};

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
	my ($self, @logpaths) = @_;
	my %path_lookup = map { (fileparse($_))[0] => $_ } @logpaths;
	my $post_data = { docs => [map { { '_id' => $_ } } keys %path_lookup] };
	my $url = join('/', $self->logfiledb, '_bulk_docs');
	my @rows = @{$self->post($url, $post_data)->data};
	return map { [$path_lookup{$_->{id}}, $_->{error} ? 1 : 0] } @rows;
}

sub _transform_doc_for_display {
	my ($doc, $lang) = @_;
	my $key = $doc->{_id};
	my ($year, $month) = $key =~ /.+\-.+\-(\d{4})\-(\d{2})/;
	my $month_list = MONTHS->{$lang} || MONTHS->{en};
	return {
		year => $year,
		month => $month_list->{$month},
		sessions => $doc->{sessions} // 0,
		requests => $doc->{requests} // 0,
		searches => $doc->{searches} // 0,
		views => $doc->{views} // 0
	};
}

sub _total_stats_row {
	my ($listing) = @_;
	return reduce
		{ _add_stats($a, $b) }
		{ year => $listing->[0]{year}, month => 'Total' },
		@$listing;
}

sub retrieve {
	my ($self, $lang, $portal, $type, $id) = @_;
	my $mask = $self->keymask($portal, $type, $id);

	my $call_args = {
		descending => 'true',
		startkey => "\"$mask.\"",
		endkey => "\"$mask\"",
		include_docs => 'true'
	};

	my $url = join('/', $self->statsdb, '_all_docs');
	my $rows = $self->get($url, $call_args)->data->{rows};

	my $listing = {};
	foreach (@$rows) {
		my $row = _transform_doc_for_display($_->{doc}, $lang);
		$listing->{$row->{year}} //= [];
		push @{$listing->{$row->{year}}}, $row;
	}

	return [map {
		{ year => $_, rows => [reverse _total_stats_row($listing->{$_}), @{$listing->{$_}}] }
	} (reverse sort keys %$listing)];
}

1;
