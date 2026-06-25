use strict;
use warnings;
use Test::More;
use URI;

use CIHM::Access::Presentation::Document;
use CIHM::Access::Presentation::DownloadClient;
use CIHM::Access::Presentation::ImageClient;

sub download_client {
  return CIHM::Access::Presentation::DownloadClient->new({
    endpoint => 'https://www-download.canadiana.ca/download',
    token_secret => 'test-token-key',
    token_ttl => 300,
  });
}

sub document {
  return CIHM::Access::Presentation::Document->new({
    record => {
      _id => 'oocihm.41831',
      key => 'oocihm.41831',
      type => 'document',
      collection => [],
      order => ['oocihm.41831.1', 'oocihm.41831.2'],
      components => {
        'oocihm.41831.1' => {
          label => 'p. 1',
          noid => '69429/m0abc',
          canonicalDownloadExtension => 'pdf',
          canonicalMasterHeight => 100,
          canonicalMasterWidth => 100,
        },
        'oocihm.41831.2' => {
          label => 'p. 2',
          noid => '69429/m0def',
          canonicalDownload => 'aip/oocihm.41831.2.pdf',
          canonicalMasterHeight => 100,
          canonicalMasterWidth => 100,
        },
      },
      ocrPdf => {
        extension => 'pdf',
        size => 123456,
      },
      noid => '69429/m0item',
    },
    image_client => CIHM::Access::Presentation::ImageClient->new({
      endpoint => 'https://image-tor.canadiana.ca/iiif/2',
    }),
    download_client => download_client(),
    domain => 'www.canadiana.ca',
  });
}

sub canonical_document {
  return CIHM::Access::Presentation::Document->new({
    record => {
      _id => 'oocihm.legacy',
      key => 'oocihm.legacy',
      type => 'document',
      collection => [],
      canonicalDownload => 'fallback/oocihm.legacy.pdf',
      file => {
        path => 'aip/oocihm.legacy.pdf',
        size => 654321,
      },
      noid => '69429/m0legacy',
    },
    image_client => CIHM::Access::Presentation::ImageClient->new({
      endpoint => 'https://image-tor.canadiana.ca/iiif/2',
    }),
    download_client => download_client(),
    domain => 'www.canadiana.ca',
  });
}

my $doc = document();

my $component = $doc->component(1);

ok !exists $component->{download_uri}, 'component data does not pre-render signed download URL';

my $component_uri = URI->new($doc->component_download_uri(1));
my %component_query = $component_uri->query_form;
is $component_uri->path, '/download/access/69429/m0abc.pdf',
  'component canonicalDownloadExtension uses access-files object path';
is $component_query{filename}, 'oocihm.41831.1.pdf',
  'component access download sets slug filename';

my $preservation_component_uri = URI->new($doc->component_download_uri(2));
is $preservation_component_uri->path, '/download/preservation/aip/oocihm.41831.2.pdf',
  'component canonicalDownload uses preservation object path';

my $item_uri = URI->new($doc->item_download);
my %item_query = $item_uri->query_form;
is $item_uri->path, '/download/access/69429/m0item.pdf',
  'ocrPdf item download uses access-files object path';
is $item_query{filename}, 'oocihm.41831.pdf',
  'ocrPdf item download sets slug filename';
is $doc->item_download_size, '121K',
  'item download size still comes from presentation metadata';

my $canonical_uri = URI->new(canonical_document()->item_download);
my %canonical_query = $canonical_uri->query_form;
is $canonical_uri->path, '/download/preservation/aip/oocihm.legacy.pdf',
  'canonicalDownload item uses exact preservation file path even when noid is present';
ok !exists $canonical_query{filename},
  'canonicalDownload preservation URL matches old Swift filename behavior';

done_testing;
