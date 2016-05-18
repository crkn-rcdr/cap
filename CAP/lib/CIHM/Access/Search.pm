package CIHM::Access::Search;

use utf8;
use strictures 2;

use Moo;
use Types::Standard qw/Str/;

use CIHM::Access::Search::Client;
use CIHM::Access::Search::Schema;

has 'server' => (
	is => 'ro',
	isa => Str,
	required => 1
);

has 'schema' => (
	is => 'ro',
	default => sub {
		return CIHM::Access::Search::Schema->new();
	}
);

has 'client' => (
	is => 'ro',
	lazy => 1,
	default => sub {
		my $self = shift;
		return CIHM::Access::Search::Client->new({
			server => $self->server,
			schema => $self->schema
		});
	}
);

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