use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::File' }

#ok( request('/retrieve')->is_success, 'Request should succeed' );


