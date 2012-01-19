use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Cron;

ok( request('/cron')->is_success, 'Request should succeed' );
done_testing();
