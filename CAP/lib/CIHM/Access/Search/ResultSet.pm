package CIHM::Access::Search::ResultSet;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/ArrayRef HashRef Int/;

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

has 'offset' => (
	is => 'ro',
	isa => Int,
	required => 1
);

has 'facets' => (
	is => 'ro',
	isa => HashRef[ArrayRef]
);

has 'publication_range' => (
	is => 'ro',
	isa => HashRef
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
			offset => $solr_output->{response}{start}
		};

		$new_args->{facet} = $solr_output->{facet_counts}{facet_fields}
			if exists $solr_output->{facet_counts};

		$new_args->{publication_range} = $solr_output->{publication_range}
			if exists $solr_output->{publication_range};

		return $class->$orig($new_args);
	}

	return $class->$orig(@args);
};

1;