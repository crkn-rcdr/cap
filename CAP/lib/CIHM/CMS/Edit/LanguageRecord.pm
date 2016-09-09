package CIHM::CMS::Edit::LanguageRecord;

use utf8;
use strictures 2;
use Moo;
use Types::Standard qw/Str/;

has [qw/title path markdown html/] => (
	is => 'ro',
	isa => Str,
	default => sub { '' }
);

1;