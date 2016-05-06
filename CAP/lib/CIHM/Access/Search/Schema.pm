package CIHM::Access::Search::Schema;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/HashRef ArrayRef Str/;

has 'fields' => (
	is => 'ro',
	isa => HashRef[ArrayRef[Str]],
	default => sub {
		return {
			default => [qw/gq tx/],
			ti => [qw/ti/],
			au => [qw/au/],
			pu => [qw/pu/],
			su => [qw/su/],
			tx => [qw/tx/],
			no => [qw/ab no no_rights no_source/]
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
	isa => HashRef[Str],
	default => sub {
		return {
			default => 'score desc',
			oldest => 'pubmin asc',
			newest => 'pubmax desc',
			seq => 'pkey asc, seq asc'
		};
	}
);

has 'types' => (
	is => 'ro',
	isa => HashRef[Str],
	default => sub {
		return {
			default => 'type:(series OR document)',
			any => '',
			page => 'type:page',
			document => 'type:document',
			series => 'type:series',
			browsable => '(-pkey:*)'
		};
	}
);

1;