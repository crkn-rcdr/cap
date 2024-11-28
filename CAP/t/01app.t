use strict;
use warnings;
use Test::More tests => 3;
use Test::WWW::Mechanize::Catalyst;

BEGIN { use_ok 'Catalyst::Test', 'CAP' }

ok(my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'CAP'));
$mech->get_ok("http://eco.localhost/");


#ok( request('/')->is_success, 'Request should succeed' );

#$mech->get_ok("/view/abc");
#$mech->title_like(qr/Error/, "/view/abc gives not found");
#$mech->get_ok("/view/oocihm.00001");
#$mech->title_like(/Histoire/, "/view/abc gives not found");
