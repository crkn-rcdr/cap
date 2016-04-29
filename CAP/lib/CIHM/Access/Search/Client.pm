package CIHM::Access::Search::Client;

use utf8;
use strictures 2;

use Moo;
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

# Parameters:

# q: the search query

# query = or_terms, { white_space, or_terms } ;
# or_terms = term, { white_space, "|", white_space, term } ;
# term = ["-"], [field_modifier, ":"], word | phrase ;
# field_modifier = "ti" | "au" | "su" | "tx" | "no" ;
# word = character, { character } ;
# phrase = '"', { every_character - '"'}, '"' ;

# character = every_character - white_space_character ;
# white_space = white_space_character, { white_space_character }
# white_space_character = ? white space characters ? ;
# every_character = ? all visible characters ? ;

# filter parameters (fq):

# collection
# type

# filter parameters (q):
# df/dt: date filtering
# lang
# pkey
# identifier
# contributor

# sorting parameter:
# sort

sub translate_query_to_solr {
	my ($self, $params) = @_;
}


1;