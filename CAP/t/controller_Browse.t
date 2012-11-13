use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Browse;

ok( request('/browse')->is_success, 'Request should succeed' );
done_testing();
