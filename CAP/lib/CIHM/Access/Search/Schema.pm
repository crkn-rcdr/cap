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
				default => [qw/gq tx/],
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
			collection => { multi_mode => 'OR' },
			pkey => { },
			df => { template => '{!tag=pubmax}pubmax:[$-01-01T00:00:00.000Z TO *]', req => qr/^\d{4}$/ },
			dt => { template => '{!tag=pubmin}pubmin:[* TO $-12-31T23:59:59.999Z]', req => qr/^\d{4}$/ },
			lang => { multi_mode => 'OR' },
			identifier => { multi_mode => 'AND' },
			depositor => { multi_mode => 'OR' }
		};
	}
);

has 'sorting' => (
	is => 'ro',
	isa => HashRef[Str|CodeRef],
	default => sub {
		return {
			alphabetical => 'label asc',
			oldest => 'pubmin asc',
			newest => 'pubmax desc',
			random => sub { my $now = time; return "random_$now asc"; },
			seq => 'seq asc'
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
