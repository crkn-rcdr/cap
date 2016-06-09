package CIHM::Access::Search::Schema;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef ArrayRef CodeRef Str/;

has 'fields' => (
	is => 'ro',
	isa => HashRef[HashRef[ArrayRef[Str]]],
	default => sub {
		return {
			general => {
				default => [qw/gq tx/],
				ti => [qw/ti/],
				au => [qw/au/],
				pu => [qw/pu/],
				su => [qw/su/],
				tx => [qw/tx/],
				no => [qw/ab no no_rights no_source/]
			}, text => {
				default => [qw/tx/],
				tx => [qw/tx/]
			}
		};
	}
);

has 'filters' => (
	is => 'ro',
	isa => HashRef[HashRef],
	default => sub {
		return {
			collection => {},
			pkey => {},
			df => { template => 'pubmax:[$-01-01T00:00:00.000Z TO *]', req => qr/^\d{4}$/ },
			dt => { template => 'pubmin:[* TO $-12-31T23:59:59.999Z]', req => qr/^\d{4}$/ },
			lang => {},
			identifier => {},
			depositor => {}
		};
	}
);

has 'sorting' => (
	is => 'ro',
	isa => HashRef[Str|CodeRef],
	default => sub {
		return {
			oldest => 'pubmin asc',
			newest => 'pubmax desc',
			random => sub { my $now = time; return "random_$now asc"; }
		};
	}
);

has 'facets' => (
	is => 'ro',
	isa => ArrayRef[Str],
	default => sub {
		return [qw/lang depositor collection/];
	}
);

1;
