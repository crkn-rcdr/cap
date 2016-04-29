use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'CIHM::Access', 'CIHM::Access::Search::Client' }

use CIHM::Access::Search::Client;

my $client = CIHM::Access::Search::Client->new();
ok $client->schema, 'has schema';