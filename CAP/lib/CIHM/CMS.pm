package CIHM::CMS;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/HashRef Str Enum/;
use Text::Undiacritic qw/undiacritic/;
use JSON qw/encode_json/;
use Scalar::Util qw/looks_like_number/;
use URI;
use CIHM::CMS::View;
use CIHM::CMS::Edit;

with 'Role::REST::Client';

has '+type' => (
	isa => Enum[qw{application/json text/html text/plain application/x-www-form-urlencoded}],
	default => sub { 'application/json' }
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

has 'languages' => (
	is => 'ro',
	isa => HashRef[Str],
	required => 1
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

# fetch a fresh new doc

sub empty_document {
	my ($self) = @_;
	return CIHM::CMS::Edit->new({}, $self->languages);
}

# fetch a doc for editing

sub edit {
	my ($self, $id) = @_;

	my $doc = $self->get("/$id", { attachments => 'true' })->data;

	if ($doc->{error}) {
		return "cms database error: $doc->{error}";
	} else {
		return CIHM::CMS::Edit->new($doc, $self->languages);
	}
}

# $args:
# id: document id
# rev: document revision
# content_type
# filename
# data
sub submit_attachment {
	my ($self, $args) = @_;

	$self->type($args->{content_type});
	$self->set_header('If-Match' => $args->{rev});
	my $response = $self->put("/$args->{id}/$args->{filename}", $args->{data});
	$self->type('application/json');

	if ($response->error) {
		use Data::Dumper; my $error = Dumper $response;
		return "cms database error: $error while submitting $args->{filename}";
	} else {
		return $response->data;
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

# $args:
# portal: current portal id
# lang: current set language
# limit: number of updates (will fetch all if undefined)
# skip: number of updates to skip (use these for pagination)
sub list_by_portal {
	my ($self, $args) = @_;

	my $call_args = {
		descending => 'true',
		startkey => encode_json ["$args->{portal}\x{FF}"],
		endkey => encode_json [$args->{portal}],
		include_docs => 'true'
	};

	my $limit = $args->{limit};
	$call_args->{limit} = int $limit if (defined $limit && looks_like_number $limit);
	my $skip = $args->{skip};
	$call_args->{skip} = int $skip if (defined $skip && looks_like_number $skip);
	my $rows = $self->get('/_design/tdr/_view/byportal', $call_args)->data->{rows};

	return [ map {
		{
			id => $_->{id},
			path => $_->{doc}{$args->{lang}}{path},
			title => $_->{doc}{$args->{lang}}{title},
			date => $_->{key}[1],
			portal => $_->{doc}{portal}
		}
	} @$rows ];
}

1;
