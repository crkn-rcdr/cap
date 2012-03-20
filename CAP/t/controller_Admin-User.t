use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Admin::User;

ok( request('/admin/user')->is_success, 'Request should succeed' );
done_testing();
