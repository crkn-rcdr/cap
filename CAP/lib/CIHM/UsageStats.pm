package CIHM::UsageStats;

use utf8;
use strictures 2;
use Moo;
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

# key is a JSON-encoded array
sub update_or_create {
	my ($self, $encoded_key, $stats) = @_;
	my ($key, $info) = $self->_decode_key($encoded_key); 

	my $url = join('/', $self->statsdb, $key);
	my $lookup = $self->get($url);
	if ($lookup->code eq '200') {
		my $doc = $lookup->data;
		delete $doc->{_id};
		$self->set_header('If-Match' => delete $doc->{_rev});
		my $new_doc = $self->_add_stats($doc, $stats);
		$self->put($url, $new_doc);
	} else {
		$self->put($url, {%$stats, %$info});
	}
}

sub _decode_key {
	my ($self, $encoded_key) = @_;
	my ($portal, $year, $month, $type, $subtype) = @{ decode_json $encoded_key };
	$type //= 'portal';
	my $couch_key = "$portal-$year-$month-$type";
	$couch_key .= "($subtype)" if $subtype;
	my $info = {
		portal => $portal,
		year => $year,
		month => $month,
		type => $type
	};
	$info->{user} = $subtype if ($type eq 'user');
	$info->{institution} = $subtype if ($type eq 'institution');
	return ($couch_key, $info);
}

sub _add_stats {
	my ($self, $doc, $stats) = @_;
	foreach (qw/sessions searches views requests/) {
		$doc ->{$_} += $stats->{$_};
	}
	return $doc;
}

sub register_logfile {
	my ($self, $logfile) = @_;
	my $found = 0;

	my $url = join('/', $self->logfiledb, $logfile);
	my $lookup = $self->get($url);
	if ($lookup->code eq '200') {
		$found = 1;
	} else {
		$self->put($url, {});
	}

	return $found;
}


1;
