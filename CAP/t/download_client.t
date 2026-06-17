use strict;
use warnings;
use Test::More;
use Crypt::Mac::HMAC qw/hmac_hex/;
use URI;

BEGIN { use_ok 'CIHM::Access::Presentation::DownloadClient' }

my $client = CIHM::Access::Presentation::DownloadClient->new({
  endpoint => 'https://www-download.canadiana.ca/download',
  token_secret => 'test-token-key',
  token_ttl => 300,
});

my $pdf_uri = URI->new($client->pdf_uri('oocihm.41831', '69429/m0abc'));
my %pdf_query = $pdf_uri->query_form;

is $pdf_uri->scheme, 'https', 'uses configured endpoint scheme';
is $pdf_uri->host, 'www-download.canadiana.ca', 'uses configured endpoint host';
is $pdf_uri->path, '/download', 'uses item download path';
is $pdf_query{slug}, 'oocihm.41831', 'sets slug';
is $pdf_query{noid}, '69429/m0abc', 'sets noid';
is $pdf_query{type}, 'PDF', 'sets PDF type';
is $pdf_query{sig}, hmac_hex(
  'SHA256',
  'test-token-key',
  join("\n", 'v2', 'oocihm.41831', '69429/m0abc', 'PDF', '', $pdf_query{expires})
), 'signs item download URL';

my $long_ttl_client = CIHM::Access::Presentation::DownloadClient->new({
  endpoint => 'https://www-download.canadiana.ca/download',
  token_secret => 'test-token-key',
  token_ttl => 21600,
});
my $before = time;
my $long_ttl_uri = URI->new($long_ttl_client->pdf_uri('oocihm.41831', '69429/m0abc'));
my %long_ttl_query = $long_ttl_uri->query_form;
my $after = time;
cmp_ok $long_ttl_query{expires}, '<=', $after + 1800, 'caps item download URL TTL at 30 minutes';
cmp_ok $long_ttl_query{expires}, '>=', $before + 1800, 'uses the maximum allowed item download URL TTL';

my $object_uri = URI->new($client->access_uri('dir/name with space.pdf', 'item.pdf'));
my %object_query = $object_uri->query_form;

is $object_uri->path, '/download/access/dir/name%20with%20space.pdf', 'uses repository object path';
like $object_uri->as_string, qr{/download/access/dir/name%20with%20space\.pdf\?}, 'escapes object path in string form';
is $object_query{filename}, 'item.pdf', 'sets filename';
is $object_query{sig}, hmac_hex(
  'SHA256',
  'test-token-key',
  join("\n", 'v1', 'access', 'dir/name with space.pdf', 'item.pdf', $object_query{expires})
), 'signs object download URL';

done_testing;
