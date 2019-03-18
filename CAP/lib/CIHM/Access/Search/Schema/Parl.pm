package CIHM::Access::Search::Schema::Parl;

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
				tx => [qw/tx/],
				no => [qw/ab no no_source/],
        call => [qw/parlCallNumber/]
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
			df => { template => '{!tag=pubmax}pubmax:[$-01-01T00:00:00.000Z TO *]', req => qr/^\d{4}$/ },
			dt => { template => '{!tag=pubmin}pubmin:[* TO $-12-31T23:59:59.999Z]', req => qr/^\d{4}$/ },
			pkey => { },
			lang => { multi_mode => 'OR' },
      chamber => { template => '{!tag=parlChamber}parlChamber:($)', multi_mode => 'OR' },
      session => { template => '{!tag=parlSession}parlSession:($)', multi_mode => 'OR' },
      type => { template => '{!tag=parlType}parlType:($)' }
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
			random => sub { my $now = time; return "random_$now asc"; },
			seq => 'seq asc'
		};
	}
);

has 'facets' => (
	is => 'ro',
	isa => ArrayRef[Str],
	default => sub {
		return [qw/lang parlType parlSession parlChamber/];
	}
);

1;
