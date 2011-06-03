use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::User' }

ok( request('/user')->is_success, 'Request should succeed' );
done_testing();
