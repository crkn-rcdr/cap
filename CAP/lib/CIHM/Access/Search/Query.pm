package CIHM::Access::Search::Query;

use utf8;
use strictures 2;

use Moo;
use List::Util qw/reduce/;
use Types::Standard qw/HashRef ArrayRef Str Bool/;

has 'schema' => (
	is => 'ro',
	required => 1
);

has 'field_key' => (
	is => 'ro',
	isa => Str,
	default => 'general'
);

has 'params' => (
	is => 'ro',
	isa => HashRef,
	required => 1
);

has 'solr_query' => (
	is => 'lazy',
	isa => Str
);

sub to_solr {
	my ($self) = @_;
	return $self->solr_query;
}

has 'cap_query' => (
	is => 'lazy',
	isa => Str
);

sub to_cap {
	my ($self) = @_;
	return $self->cap_query;
}

has 'query_terms' => (
	is => 'lazy',
	isa => ArrayRef
);

has 'has_text_terms' => (
	is => 'rwp',
	isa => Bool,
	default => 0
);

# Parameters:

# q#|#: query terms (see below)

# filter parameters 
# collection
# df/dt: date filtering
# lang
# pkey
# identifier
# depositor
sub _build_solr_query {
	my ($self) = @_;

	my @terms = ();
	foreach my $or_group (@{ $self->query_terms }) {
		my $joined_group = _skip_join(' OR ', map { $self->_analyze_term($_) } @{$or_group});
		$joined_group = "($joined_group)" if (@{$or_group} > 1);
		push @terms, $joined_group;
	}

	foreach my $filter (keys %{$self->schema->filters}) {
		push @terms, $self->_filter_query($filter, $self->params->{$filter});
	}

	return _skip_join(' ', @terms) || '*:*';
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

sub _build_cap_query {
	my ($self) = @_;

	my @terms = ();
	foreach my $or_group (@{ $self->query_terms }) {
		my $joined_group = _skip_join(' | ', @{$or_group});
		push @terms, $joined_group;
	}

	return _skip_join(' ', @terms);
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
sub _build_query_terms {
	my ($self) = @_;
	my $key_exp = qr/^q(\d+)(?:\.(\d+))?$/;
	my @value_index = map {
		$_ =~ /$key_exp/;
		defined $1 ? [$1, $2, $self->params->{$_}] : ()
	} keys $self->params;

	my @sort = ();
	foreach (@value_index) {
		my ($x, $y, $value) = @{$_};
		$y ||= 0;
		$sort[$x] = [] unless (defined $sort[$x]);
		$sort[$x][$y] = $value;
	}

	return [@sort];
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
	return '' if ($field_modifier && !exists $self->schema->fields->{$self->field_key}{$field_modifier});

	$self->_set_has_text_terms(1) if grep(/$field_modifier/, keys $self->schema->fields->{text});

	$token = $self->_parse_token($token);
	my @result;
	push(@result, '-') if ($negation);
	push @result, '(';
	push @result,
		reduce { $a . ' OR ' . $b }
		map { "$_:$token" }
		@{$self->schema->fields->{$self->field_key}{$field_modifier}};
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