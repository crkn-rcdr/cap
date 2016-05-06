package CIHM::Access::Search::Client;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;
use List::Util qw/reduce/;
with 'Role::REST::Client';

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

has 'root_collection' => (
	is => 'ro',
	isa => Str,
	required => 1
);

# Parameters:

# q#: the search query (divided into or_group q0, q1, q2, etc.)

# or_group = term, { or_divider, term } ;
# term = ["-"], [field_modifier, ":"], word | phrase ;
# field_modifier = "ti" | "au" | "pu" | "su" | "tx" | "no" ;
# word = character, { character } ;
# phrase = '"', { every_character - ('"' | or_divider) }, '"' ;
# or_divider = white_space, "|", white_space

# character = every_character - white_space_character ;
# white_space = white_space_character, { white_space_character }
# white_space_character = ? white space characters ? ;
# every_character = ? all visible characters ? ;

# filter parameters (q):
# df/dt: date filtering
# lang
# pkey
# identifier
# depositor

# sorting parameter:
# sort

sub translate_query_to_solr {
	my ($self, $query_params) = @_;
	my $solr_params = { 'q.op' => 'AND' };

	$solr_params->{q} = $self->_build_query_terms($query_params);

	return $solr_params;
}

# query terms keys look like q0, q1, q2, etc.
sub _build_query_terms {
	my ($self, $query_params) = @_;
	my @or_groups = ();
	foreach my $or_group ($self->_sorted_query_values($query_params)) {
		my @terms = ();
		foreach my $term (split /\s+\|\s+/, $or_group) {
			my $analyzed_term = $self->_analyze_term($term);
			push @terms, $analyzed_term if ($analyzed_term);
		}
		if (@terms) {
			my $joined_or_group = join ' OR ', @terms;
			push @or_groups, @terms > 1 ? "($joined_or_group)" : $joined_or_group;
		}
	}

	return join ' ', @or_groups;
}

sub _sorted_query_values {
	my ($self, $query_params) = @_;
	return 
		map { $query_params->{$_} }
		sort { ($a =~ /q(\d+)/)[0] <=> ($b =~ /q(\d+)/)[0] }
		grep { /q(\d+)/ }
		keys $query_params;
}

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
	my $result = '';
	$result .= '-' if ($negation);
	$result .= '(';
	$result .=
		reduce { $a . ' OR ' . $b }
		map { "$_:$token" }
		@{$self->schema->fields->{$field_modifier}};
	$result .= ')';

	return $result;

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