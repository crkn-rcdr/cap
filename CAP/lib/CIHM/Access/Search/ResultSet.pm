package CIHM::Access::Search::ResultSet;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/ArrayRef HashRef Int Str/;
use List::Util qw/min/;
use POSIX qw/ceil/;

has 'documents' => (
	is => 'ro',
	isa => ArrayRef[HashRef],
	required => 1
);

has 'hits' => (
	is => 'ro',
	isa => Int,
	required => 1
);

has 'hits_per_page' => (
	is => 'ro',
	isa => Int,
	required => 1
);

has 'first' => (
	is => 'ro',
	isa => Int,
	required => 1
);

has 'last' => (
	is => 'lazy',
	isa => Int,
	builder => sub { my $self = shift; $self->first + @{ $self->documents } - 1 }
);

has 'page' => (
	is => 'lazy',
	isa => Int,
	builder => sub { my $self = shift; int($self->first / $self->hits_per_page) + 1 }
);

has 'pages' => (
	is => 'lazy',
	isa => Int,
	builder => sub {
		my $self = shift;
		if ($self->hits_per_page) {
			ceil($self->hits / $self->hits_per_page);
		} else {		
			0
		}
	}
);

has 'facets' => (
	is => 'ro',
	isa => HashRef[ArrayRef]
);

has 'pubmin' => (
	is => 'ro',
	isa => Str
);

has 'pubmax' => (
	is => 'ro',
	isa => Str
);

has 'plabel' => (
	is => 'ro',
	isa => Str
);

# expect a hashref that needs to be mangled
around BUILDARGS => sub {
	my ($orig, $class, @args) = @_;
	my $solr_output = $args[0];

	if (ref($solr_output) eq 'HASH' &&
		exists $solr_output->{responseHeader} &&
		exists $solr_output->{responseHeader}{status} &&
		$solr_output->{responseHeader}{status} == 0) {
		my $new_args = {
			documents => $solr_output->{response}{docs},
			hits => $solr_output->{response}{numFound},
			hits_per_page => $solr_output->{responseHeader}{params}{rows} // 10, # TODO: fix this magic number
			first => $solr_output->{response}{start} + 1 # solr start is 0-based
		};

		$new_args->{facets} = _handle_facets($solr_output->{facet_counts}{facet_fields})
			if exists $solr_output->{facet_counts};

		$new_args->{stats} = $solr_output->{stats}{stats_fields}
			if exists $solr_output->{stats};

		if ($solr_output->{response}{numFound} &&
			exists $solr_output->{stats} &&
			exists $solr_output->{stats}{stats_fields}{pubmin}) {
			%$new_args = ( %$new_args, %{_handle_stats($solr_output->{stats}{stats_fields}) } );
		}

		return $class->$orig($new_args);
	}

	return $class->$orig(@args);
};

sub _handle_facets {
	my $facets = shift;
	foreach my $field (keys %$facets) {
		my @a = @{ $facets->{$field} };
		my @b = ();
		while (@a) {
			push @b, { name => shift @a, count => shift @a };
		}
		$facets->{$field} = \@b;
	}
	return $facets;
}

sub _handle_stats {
	my $stats = shift;
	my $args = {};
	if (exists $stats->{pubmin}) {
		$args->{pubmin} = substr($stats->{pubmin}{min} || '', 0, 4);
	}
	if (exists $stats->{pubmax}) {
		$args->{pubmax} = substr($stats->{pubmax}{max} || '', 0, 4);
	}
	return $args;
}

1;
