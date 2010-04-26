use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }
BEGIN { use_ok 'CAP::Controller::Common' }

ok( request('/common')->is_success, 'Request should succeed' );
done_testing();
