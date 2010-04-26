use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::Show' }

ok( request('/show')->is_success, 'Request should succeed' );


