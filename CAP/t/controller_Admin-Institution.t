use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Admin::Institution;

ok( request('/admin/institution')->is_success, 'Request should succeed' );
done_testing();
