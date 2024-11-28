use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'CIHM::Access::Search' }

use CIHM::Access::Search;

my $s = CIHM::Access::Search->new({ server => 'http://localhost:8983/solr/cosearch' });
ok $s->schema, 'has schema';

cmp_deeply $s->transform_query({ q => 'hello goodbye' }),
	{ 'q0|0' => 'hello', 'q1|0' => 'goodbye' },
	'basic query parsing';

cmp_deeply $s->transform_query({ q => '-hello -su:goodbye' }),
	{ 'q0|0' => '-hello', 'q1|0' => '-su:goodbye' },
	'handling field modifiers and negation';

cmp_deeply $s->transform_query({ q => 'hello -goodbye su:forever', field => 'au' }),
	{ 'q0|0' => 'au:hello', 'q1|0' => '-au:goodbye', 'q2|0' => 'su:forever' },
	'handling base field modifiers';

cmp_deeply $s->transform_query({ q => 'su:"hello goodbye" forever' }),
	{ 'q0|0' => 'su:"hello goodbye"', 'q1|0' => 'forever' },
	'handling phrases';

cmp_deeply $s->transform_query({ q => 'hello | su:goodbye | au:forever my | friend' }),
	{ 'q0|0' => 'hello', 'q0|1' => 'su:goodbye', 'q0|2' => 'au:forever',
	  'q1|0' => 'my', 'q1|1' => 'friend' },
	'handling ORs';

cmp_deeply $s->transform_query({ q => '| hello goodbye' }),
	{ 'q0|0' => 'hello', 'q1|0' => 'goodbye' },
	'throw out bad OR at beginning';

cmp_deeply $s->transform_query({ q => 'hello | | goodbye' }),
	{ 'q0|0' => 'hello', 'q0|1' => 'goodbye' },
	'throw out bad OR in middle';

cmp_deeply $s->transform_query({ q => 'hello goodbye |' }),
	{ 'q0|0' => 'hello', 'q1|0' => 'goodbye' },
	'throw out bad OR at end';

cmp_deeply $s->transform_query({ q => 'hello goodbye', collection => 'nas' }),
	{ 'q0|0' => 'hello', 'q1|0' => 'goodbye', collection => 'nas' },
	'pass filters through';


done_testing;
