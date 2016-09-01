package CIHM::CMS;

use utf8;
use strictures 2;
use Moo;
use Text::Undiacritic qw/undiacritic/;
use JSON qw/encode_json/;
use Scalar::Util qw/looks_like_number/;
use URI;
use CIHM::CMS::View;

with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

# args:
# portal: current portal id
# path: desired page path
# lang: current set language
# base_url: base url for relative redirects
# 
# returns:
# CIHM::CMS::View if the document exists and you're at the right place
# URI for redirect if you're pointed to a right place
# undef if there's nothing there
sub view {
	my ($self, $args) = @_;

	my $entry = $self->get('/_design/tdr/_view/aliases',
		{ key => encode_json [$args->{portal}, _strip_path($args->{path})] },
	)->data->{rows}[0];

	return "No CMS entry for $args->{path}" unless $entry;

	my $value = $entry->{value}->{$args->{lang}};

	return "Document at $args->{path} does not contain information in language $args->{lang}" unless $value;

	if (_strip_path($args->{path}) eq _strip_path($value)) {
		my $key = $entry->{id};
		my $doc = $self->get("/$key")->data;
		return "Document at $args->{path} has not been marked as published." unless $doc->{publish};
		my $body = $self->get("/$key/$args->{lang}.html")->response->content || '';
		return CIHM::CMS::View->new($doc, $body, $args->{lang});
	} else {
		return URI->new_abs($value, $args->{base_url});
	}
}

sub _strip_path {
	return undiacritic(lc(shift));
}

# fetch a doc for editing

sub edit {
	my ($self, $id) = @_;

	my $doc = $self->get("/$id")->data;

	if ($doc->{error}) {
		return "cms database error: $doc->{error}";
	} else {
		$doc->{id} = delete $doc->{_id};
		return $doc;
		#return CIHM::CMS::Edit->new($doc);
	}
}

# $args:
# portal: current portal id
# lang: current set language
# limit: number of updates (will fetch all if undefined)
sub updates {
	my ($self, $args) = @_;

	my $call_args = {
		descending => 'true',
		startkey => encode_json [$args->{portal}, "$args->{lang}\x{FF}"],
		endkey => encode_json [$args->{portal}, "$args->{lang}"]
	};

	my $limit = $args->{limit};
	$call_args->{limit} = int $limit if (defined $limit && looks_like_number $limit);
	my $rows = $self->get('/_design/tdr/_view/updates', $call_args)->data->{rows};

	return [ map {
		{
			path => $_->{value}{path},
			title => $_->{value}{title},
			date => $_->{key}[1]
		}
	} @$rows ];
}

1;
