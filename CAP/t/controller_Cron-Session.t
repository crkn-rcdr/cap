use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Cron::Session;

ok( request('/cron/session')->is_success, 'Request should succeed' );
done_testing();
