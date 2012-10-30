use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Reports::User;

ok( request('/reports/user')->is_success, 'Request should succeed' );
done_testing();
