package CIHM::CMR::Plugin::MulticulturalCanada;

use strict;
use warnings;
use feature qw(switch);
use utf8;
use CIHM::CMR::Common;
use Encode;

use Exporter qw(import);
our @EXPORT = qw(preprocess);

sub preprocess {
    my($src) = @_;
    my $record = $src->documentElement();

    # Media type
    element($src, $record, 'media', {}, media_mime($src->findvalue('/record/format[string-length(@type) = 0]')), 1);
    

    # Split subjects into individual elements
    foreach my $node ($src->findnodes('/record/subject')) {
        my $lang = $node->getAttribute('lang');
        foreach my $subject (split('; ', $node->findvalue('.'))) {
            element($src, $record, 'subj', { lang => $lang }, $subject);
        }
    }

    # Extract notes
    foreach my $node ($src->findnodes('/record/format[@type="duration"]')) {
        element($src, $record, 'note', { type => 'extent' }, $node->findvalue('.'));
    }
    foreach my $node ($src->findnodes('/record/rights')) {
        element($src, $record, 'note', { type => 'rights' }, $node->findvalue('.'));
    }

    return $src;
}

1;
