use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Institution;

ok( request('/institution')->is_success, 'Request should succeed' );
done_testing();
