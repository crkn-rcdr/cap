use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Link;

ok( request('/link')->is_success, 'Request should succeed' );
done_testing();
