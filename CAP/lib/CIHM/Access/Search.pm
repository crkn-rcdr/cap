package CIHM::Access::Search;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
with 'Role::REST::Client';

use CIHM::Access::Search::Query;
use CIHM::Access::Search::ResultSet;
use CIHM::Access::Search::Schema;

has '+type' => (
	default => 'application/json'
);

has 'schema' => (
	is => 'ro',
	default => sub {
		return CIHM::Access::Search::Schema->new();
	}
);

sub general {
	my ($self, $root_collection, $offset, $params) = @_;
	my $query = $self->query($params);
	my $resultset = $self->_request(
		'/search/general',
		{
			root_collection => $root_collection,
			sort => $params->{so},
			offset => $offset,
			facet => 1,
			date_stats => 1
		},
		$query
	);

	return {
		query => $query,
		resultset => $resultset
	};
}

sub _request {
	my ($self, $handler, $options, $query) = @_;

	my $data = {};
	$data->{query} = $query->to_solr;

	if ($options->{root_collection}) {
		$data->{filter} = 'collection:' . $options->{root_collection};
	}

	my $sort = $self->_get_sort($options->{so});
	$data->{sort} = $sort if ($sort);

	$data->{offset} = $options->{offset} || 0;	
	$data->{limit} = $options->{limit} if (defined $options->{limit});
	$data->{fields} = $options->{fields} if (defined $options->{fields});

	$data->{params} = {};
	$data->{params}{'facet.field'} = $self->schema->facets if $options->{facet};

	if ($options->{date_stats}) {
		$data->{params}{stats} = 'true';
		$data->{params}{'stats.field'} = [
			'{!min=true}pubmin',
			'{!max=true}pubmax'
		];
	}

	my $output = $self->post($handler, $data)->data;
	if (exists $output->{responseHeader} &&
		exists $output->{responseHeader}{status} &&
		$output->{responseHeader}{status} == 0) {
		return CIHM::Access::Search::ResultSet->new($output);
	} else {
		return $output;
	}
}

sub _get_sort {
	my ($self, $so) = @_;
	if (defined $so && exists $self->schema->sorting->{$so}) {
		my $def = $self->schema->sorting->{$so};
		return ref($def) eq 'CODE' ? &$def : $def;
	}
	return undef;
}

# builds a CIHM::Access::Search::Query using the local schema
sub query {
	my ($self, $params) = @_;
	return CIHM::Access::Search::Query->new({ schema => $self->schema, params => $params });
}

# transforms a posted search into terms to redirect to
sub transform_query {
	my ($self, $post_params) = @_;
	my $get_params = {};

	# copy over filter parameters
	for (keys $self->schema->filters) {
		$get_params->{$_} = $post_params->{$_} if exists $post_params->{$_};
	}

	# "Search in:" parameter
	my $base_field = $post_params->{field};
	$base_field = '' unless ($base_field && exists $self->schema->fields->{$base_field});

	my @pointer = (0,0);
	my $or = 0;
	while (($post_params->{q} || '') =~ /
		(-)?+				# negation
		(?:([a-z]+):)?+		# field_modifier
		(
			[^\s\"]+ |		# word
			\"[^\"]+\"		# phrase
		)    
    /gx) {
		my ($negation, $field_modifier, $token) = ($1 || '', $2 || '', $3 || '');

		# we have an OR. the pointer's y-value should change, not the x-value
		if ($negation eq '' && $field_modifier eq '' && $token eq '|') {
			# only OR if there's something to OR with
			if ($get_params->{_term_key($pointer[0] - 1, $pointer[1])}) {
				$pointer[0] -= 1;
				$pointer[1] += 1;
				$or = 1;
			}

			next;
		}

		$pointer[1] = 0 unless $or;

		$field_modifier = $field_modifier || $base_field;
		$field_modifier .= ':' if $field_modifier;
		$get_params->{_term_key(@pointer)} = "$negation$field_modifier$token";

		$pointer[0] += 1;
		$or = 0;
    }

 	return $get_params;
}

sub _term_key {
	my ($x, $y) = @_;
	return "q$x|$y";
}

1;