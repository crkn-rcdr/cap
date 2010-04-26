use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::Retrieve' }

ok( request('/retrieve')->is_success, 'Request should succeed' );


