package CIHM::Access::Search::Client;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use List::Util qw/reduce/;
use CIHM::Access::Search::ResultSet;
with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has 'schema' => (
	is => 'ro',
	required => 1
);

sub request {
	my ($self, $handler, $options, $query_params) = @_;

	my $data = {};
	$data->{query} = $self->_build_query_terms($query_params) || '*:*';

	if ($options->{root_collection}) {
		$data->{filter} = 'collection:' . $options->{root_collection};
	}

	my $sort = $self->_get_sort($query_params->{so});
	$data->{sort} = $sort if ($sort);

	$data->{offset} = $options->{offset} || 0;	
	$data->{limit} = $options->{limit} if (defined $options->{limit});

	$data->{params} = { 'facet.field' => $self->schema->facets } if $options->{facet};

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

# Parameters:

# q#|#: query terms (see below)

# filter parameters 
# collection
# df/dt: date filtering
# lang
# pkey
# identifier
# depositor
sub _build_query_terms {
	my ($self, $query_params) = @_;
	my @terms = ();
	foreach my $or_group ($self->_sorted_query_values($query_params)) {
		my $joined_group = _skip_join(' OR ', @{$or_group});
		$joined_group = "($joined_group)" if (@{$or_group} > 1);
		push @terms, $joined_group;
	}

	foreach my $filter (keys %{$self->schema->filters}) {
		push @terms, $self->_filter_query($filter, $query_params->{$filter});
	}

	return _skip_join(' ', @terms);
}

sub _filter_query {
	my ($self, $filter, $param) = @_;

	return '' unless ($param);

	if (ref($param) eq 'ARRAY') {
		return map { $self->_filter_query($filter, $_) } @{$param};
	}

	my $filter_opts = $self->schema->filters->{$filter};
	my $template = $filter_opts->{template} || "$filter:\$";
	$template =~ s/\$/$param/g;
	return $template;
}

# join, but ignore empty strings
sub _skip_join {
	my ($separator, @list) = @_;
	return reduce { length $a && length $b ? "$a$separator$b" :
                    length $a              ? $a                 :
                    length $b              ? $b                 :
                    '' } '', @list;
}

# query term keys are of two possible forms:
# q$x if not part of an or group
# q$x|$y if part of an or group
sub _sorted_query_values {
	my ($self, $query_params) = @_;
	my $key_exp = qr/^q(\d+)(?:\|(\d+))?$/;
	my @value_index = map {
		$_ =~ /$key_exp/;
		defined $1 ? [$1, $2, $query_params->{$_}] : ()
	} keys $query_params;

	my @sort = ();
	foreach (@value_index) {
		my ($x, $y, $value) = @{$_};
		$y ||= 0;
		$sort[$x] = [] unless (defined $sort[$x]);
		$sort[$x][$y] = $self->_analyze_term($value);
	}

	return @sort;
}

# term = ["-"], [field_modifier, ":"], word | phrase ;
# field_modifier = "ti" | "au" | "pu" | "su" | "tx" | "no" ;
# word = character, { character } ;
# phrase = '"', { every_character - ('"' | or_divider) }, '"' ;
# or_divider = white_space, "|", white_space

# character = every_character - white_space_character ;
# white_space = white_space_character, { white_space_character }
# white_space_character = ? white space characters ? ;
# every_character = ? all visible characters ? ;
sub _analyze_term {
	my ($self, $term) = @_;
	my ($negation, $field_modifier, $token) = $term =~ /
		(-)?+				# negation
		(?:([a-z]+):)?+		# field_modifier
		(
			[^\s\"]+ |		# word
			\"[^\"]+\"		# phrase
		)
	/x;

	$field_modifier = 'default' unless ($field_modifier);

	return '' unless ($token && $token ne ':');
	return '' if ($field_modifier && !exists $self->schema->fields->{$field_modifier});

	$token = $self->_parse_token($token);
	my @result;
	push(@result, '-') if ($negation);
	push @result, '(';
	push @result,
		reduce { $a . ' OR ' . $b }
		map { "$_:$token" }
		@{$self->schema->fields->{$field_modifier}};
	push @result, ')';

	return join '', @result;

}

sub _parse_token {
	my ($self, $token) = @_;

	$token = lc $token;

	# escape some special characters
	if (substr($token, 0, 1) eq '"') {
		$token =~ s/[*?-]/ /g;
		$token =~ s/([+:!(){}\[\]^~\\])/\\$1/g;
	}
	else {
		$token =~ s/(["+:!(){}\[\]^~\\])/\\$1/g;
	}

	return $token;
}


1;