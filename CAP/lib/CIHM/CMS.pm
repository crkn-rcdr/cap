package CIHM::CMS;

use utf8;
use strictures 2;
use Moo;
#use Text::Undiacritic qw/undiacritic/;
use JSON qw/encode_json/;
use URI;
use CIHM::CMS::View;

with 'Role::REST::Client';

has '+type' => (
	default => 'application/json'
);

has '+persistent_headers' => (
	default => sub { return { Accept => 'application/json' }; }
);

# args:
# portal: current portal id
# path: desired page path
# lang: current set language
# base_url: base url for relative redirects
# 
# returns:
# CIHM::CMS::View if the document exists and you're at the right place
# URI for redirect if you're pointed to a right place
# undef if there's nothing there
sub view {
	my ($self, $args) = @_;

	my $entry = $self->get('/_design/tdr/_view/aliases',
		{ key => encode_json [$args->{portal}, _strip($args->{path})] },
	)->data->{rows}[0];

	return undef unless $entry;

	my $value = $entry->{value}->{$args->{lang}};
	if (_strip($args->{path}) eq _strip($value)) {
		my $key = $entry->{id};
		my $doc = $self->get("/$key")->data;
		my $body = $self->get("/$key/" . $args->{lang} . '.html')->response->content;
		return CIHM::CMS::View->new($doc, $body, $args->{lang});
	} else {
		return URI->new_abs($value, $args->{base_url});
	}
}

sub _strip {
	my ($token) = @_;
	$token =~ tr/ÀàÁáÂâÄäÃãÅå/a/;
	$token =~ tr/ÈèÉéÊêËë/e/;
	$token =~ tr/ÌìÍíÎîÏï/i/;
	$token =~ tr/ÒòÓóÔôÖöÕõØo/o/;
	$token =~ tr/ÙùÚúÛûÜü/u/;
	$token =~ tr/Çç/c/;
	$token =~ tr/Ññ/n/;
	$token =~ s/[Œœ]/oe/g;
	$token =~ s/[Ææ]/ae/g;
	$token = lc($token);
	return $token;
}

1;
