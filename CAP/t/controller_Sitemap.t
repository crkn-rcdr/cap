use strict;
use warnings;
use Test::More;


use Catalyst::Test 'CAP';
use CAP::Controller::Sitemap;

ok( request('/sitemap')->is_success, 'Request should succeed' );
done_testing();
