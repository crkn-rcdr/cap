use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'CIHM::Access', 'CIHM::Access::Search::Client' }

use CIHM::Access::Search::Client;

my $client = CIHM::Access::Search::Client->new({ root_collection => 'eco' });
ok $client->schema, 'has schema';

is $client->_analyze_term('hi'), "(gq:hi OR tx:hi)", 'default word analyzing';
is $client->_analyze_term('"hi or bye"'), '(gq:"hi or bye" OR tx:"hi or bye")', 'default phrase analyzing';
is $client->_analyze_term('su:hi'), "(su:hi)", 'specific field analyzing';
is $client->_analyze_term('-su:"hi or bye"'), '-(su:"hi or bye")', 'negation';
is $client->_analyze_term(''), '', 'ignore empty terms';
is $client->_analyze_term('""'), '', 'ignore empty phrases';
is $client->_analyze_term('-su:'), '', 'ignore empty words after field modifiers';
is $client->_analyze_term('su:""'), '', 'ignore empty phrases after field modifiers';
is $client->_analyze_term('borg:plook'), '', 'ignore bad field modifiers';
is $client->_analyze_term('^*)@$('), '(gq:\^*\)@$\( OR tx:\^*\)@$\()', 'escape special characters';

is $client->_filter_query('collection', 'hfc'), 'collection:hfc', 'handle query filter';
is $client->_filter_query('df', '1850'), 'pubmax:[1850-01-01T00:00:00.000Z TO *]', 'handle query filter with custom template';
is(($client->_filter_query('identifier', ['P04', 'S01']))[1], 'identifier:S01', 'handle multiple filters from same key');

is $client->_build_query_terms({
	q0 => 'hi'
}), '(gq:hi OR tx:hi)', 'handle regular term';
is $client->_build_query_terms({
	q0 => 'su:"upper canada"'
}), '(su:"upper canada")', 'handle regular phrase';
is $client->_build_query_terms({
	'q0|0' => 'hi', 'q0|1' => 'su:bye', 'q0|2' => '-pu:why', q1 => 'hello'
}), '((gq:hi OR tx:hi) OR (su:bye) OR -(pu:why)) (gq:hello OR tx:hello)', 'handle or terms';
is $client->_build_query_terms({
	q0 => 'hi', q1 => 'su:bye', q2 => '-pu:why'
}), '(gq:hi OR tx:hi) (su:bye) -(pu:why)', 'handle multiple regular terms';
is $client->_build_query_terms({
	q0 => '"this is a phrase"', q1 => 'su:canada'
}), '(gq:"this is a phrase" OR tx:"this is a phrase") (su:canada)', 'handle multiple terms with phrases';
is $client->_build_query_terms({
	q0 => ''
}), '', 'return nothing when given nothing';
is $client->_build_query_terms({
	q0 => 'hi', q1 => '#$89', q2 => 'su:bye', q3 => 'au:'
}), '(gq:hi OR tx:hi) (gq:#$89 OR tx:#$89) (su:bye)', 'discard garbage terms';

# I can't know which order this comes in
cmp_deeply $client->_build_query_terms({
	q0 => 'hi', df => '1850', collection => 'hfc'
}), any('(gq:hi OR tx:hi) pubmax:[1850-01-01T00:00:00.000Z TO *] collection:hfc',
        '(gq:hi OR tx:hi) collection:hfc pubmax:[1850-01-01T00:00:00.000Z TO *]'), 'handle filters';

done_testing;