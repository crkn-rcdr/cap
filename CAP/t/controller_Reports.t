use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Reports;

ok( request('/reports')->is_success, 'Request should succeed' );
done_testing();
