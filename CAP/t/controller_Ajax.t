use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::Ajax' }

#ok( request('/ajax')->is_success, 'Request should succeed' );
done_testing();
