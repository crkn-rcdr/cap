package CIHM::CMR::Plugin::ECO2;


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
    my $eco2 = $src->documentElement();

    # Find the default document language.
    my $default_lang = $eco2->findvalue('substring(//marc/field[@type="008"], 36, 3)');

    # Set an explicit type for the document. Set the sequence for issues.
    if ($eco2->getAttribute('parent')) {
        $eco2->setAttribute('type', 'issue');
        my $seq = $eco2->getAttribute('id');
        $seq =~ s/.*_//;
        element($src, $eco2, 'seq', {}, $seq);
    }
    elsif ($eco2->findvalue('digital')) {
        $eco2->setAttribute('type', 'monograph');
    }
    else {
        $eco2->setAttribute('type', 'serial');
    }

    # Set an explicit label based on the 245$a and $b fields
    my $marc245a = $eco2->findvalue('//marc/field[@type="245"]/subfield[@type="a"]');
    my $marc245b = $eco2->findvalue('//marc/field[@type="245"]/subfield[@type="b"]');
    $marc245a = "$marc245a : $marc245b" if ($marc245b);
    element($src, $eco2, 'label', {}, $marc245a);

    # If this item has no parent, make the collection group its parent.
    # Otherwise, make the collection a group.
    if ($eco2->getAttribute('parent')) {
        element($src, $eco2, 'gkey', {}, _collection($eco2->findvalue('normalize-space(//collections/collection[@lang="en"])')));
    }
    else {
        $eco2->setAttribute('parent', _collection($eco2->findvalue('normalize-space(//collections/collection[@lang="en"])')));
    }

    # Set the document languages
    element($src, $eco2, 'lang', {}, $default_lang);
    foreach my $lang ($eco2->findnodes('//marc/field[@type="041"]/subfield')) {
        $lang = lc($lang->findvalue('.'));
        $lang =~ s/[^a-z]//g;
        my @langs = ($lang =~ /.../g);
        foreach my $code (@langs) {
            element($src, $eco2, 'lang', {}, $code);
        }
    }

    # Titles
    foreach my $node ($eco2->findnodes('//marc/field[@type="130" or @type="245" or @type="246" or @type="730"]')) {
        element($src, $eco2, 'ti', { lang => $default_lang, type => _marctype($node->getAttribute('type')) }, $node->findvalue('normalize-space(.)'));
    }
    # Authors
    foreach my $node ($eco2->findnodes('//marc/field[@type="100" or @type="110" or @type="111" or @type="700" or @type="710" or @type="711"]')) {
        element($src, $eco2, 'au', { lang => $default_lang, type => _marctype($node->getAttribute('type')) }, $node->findvalue('normalize-space(.)'));
    }

    # Publication Info
    element($src, $eco2, 'pu', { lang => $default_lang, type => 'main' }, $eco2->findvalue('normalize-space(//marc/field[@type="260"])'));
    
    # Subjects
    foreach my $node ($eco2->findnodes('//marc/field[@type="600" or @type="610" or @type="630" or @type="650" or @type="651"]')) {
        my $lang = 'eng';
        $lang = 'fre' if ($node->getAttribute('i2') == 6);
        my @subject = ();
        foreach my $subfield ($node->findnodes('subfield')) {
            push(@subject, '--') if ($subfield->getAttribute('type') =~ /^v|x|y|z$/);
            push(@subject, $subfield->findvalue('normalize-space(.)'));
        }
        element($src, $eco2, 'su', { lang => $lang, type => _marctype($node->getAttribute('type')) }, join(' ', @subject));
    }
    # Notes
    foreach my $node ($eco2->findnodes('//marc/field[@type="250" or @type="310" or @type="321" or @type="362" or @type="500" or @type="504" or @type="505" or @type="510" or @type="515" or @type="520" or @type="534" or @type="546" or @type="580" or @type="595" or @type="780" or @type="787" or @type="800" or @type="810" or @type="811" or @type="830"]')) {
        element($src, $eco2, 'no', { lang => $default_lang, type => _marctype($node->getAttribute('type')) }, $node->findvalue('normalize-space(.)'));
    }

    

    #
    # Process the pages
    #

    foreach my $page ($eco2->findnodes('//pages/page')) {
        # Get the label from a combination of the page number and feature
        # code
        my $pgno = $page->getAttribute('n');
        my $pgfeat = $page->getAttribute('type');
        if ($pgno && $pgfeat) {
            element($src, $page, 'clabel', {}, join("", "p. $pgno (", _pgfeature($pgfeat, $default_lang), ")"));
        }
        elsif ($pgfeat) {
            element($src, $page, 'clabel', {}, _pgfeature($pgfeat, $default_lang));
        }
        else {
            element($src, $page, 'clabel', {}, "p. $pgno");
        }

        # The page belongs to the collection group and, if it is part of
        # an issue, the parent serial.
        element($src, $page, 'gkey', {}, _collection($eco2->findvalue('normalize-space(//collections/collection[@lang="en"])')));
        if ($eco2->getAttribute('parent')) {
            element($src, $page, 'gkey', {}, $eco2->getAttribute('parent'));
        }

        # The page text - use the new text if we have it. Otherwise, fall
        # back to the old.
        if ($page->findvalue('Words')) {
            element($src, $page, 'text', { lang => $default_lang, type => 'content' }, $page->findvalue('normalize-space(Words)'));
        }
        else {
            element($src, $page, 'text', { lang => $default_lang, type => 'content' }, $page->findvalue('normalize-space(pagetext)'));
        }
    }


    return $src;
}

sub _collection
{
    my($name) = @_;

    my $collections = {
        'English Canadian Literature' => 'ecl',
        'History of French Canada' => 'hfc',
        'Periodicals' => 'per'
    };

    return $collections->{$name} || '!!!unknown collection';
}

sub _pgfeature
{
    my($type, $lang) = @_;
    my $feature = {
        Advertisement => { eng => 'advertisement', fre => 'annonce publicitiare' },
        Bib => { eng => 'bibliography', fre => 'bibliographie' },
        Blank => { eng => 'blank page', fre => 'page blanche' },
        Cover => { eng => 'cover', fre => 'page couverture' },
        Index => { eng => 'index', fre => 'index' },
        ILL => { eng => 'illustration', fre => 'illustration' },
        LOI => { eng => 'list of illustrations', fre => 'liste des illustrations' },
        Map => { eng => 'map', fre => 'carte' },
        'Non-Blank' => { eng => 'unnumbered', fre => 'page non-numérotée' },
        Table => { eng => 'table', fre => 'table' },
        Target => { eng => 'technical data sheet', 'fre' => 'page de données techniques'},
        'Title Page'=> { eng => 'title page', 'fre' => 'page de titre' },
        TOC => { eng => 'table of contents', 'fre' => 'table des matières' },
    };
    return $feature->{$type}->{$lang} || "!!!$type";
}

sub _marctype
{
    my($code) = @_;
    # 6xx, 7xx, and (usually, for our purposes) 8xx fields are equivalent to 1xx fields.
    $code = $code - 500 if ($code > 599 && $code < 700);
    $code = $code - 600 if ($code > 699 && $code < 800);
    $code = $code - 900 if ($code > 999 && $code < 900);
    given ($code) {
        when(100) { return "person" }
        when(110) { return "corporate" }
        when(111) { return "corporate" }
        when(130) { return "uniform" }
        when(150) { return "topical" }
        when(151) { return "geographic" }
        when(245) { return "main" }
        when(246) { return "alternate" }
        when(250) { return "publication" }
        when(310) { return "frequency" }
        when(362) { return "date" }
        when(500) { return "general" }
        when(504) { return "general" }
        when(505) { return "general" }
        when(515) { return "general" }
        when(520) { return "descriptive" }
        when(534) { return "extent" }
        when(546) { return "language" }
        when(800) { return "person" }
        when(810) { return "corporate" }
        when(830) { return "uniform" }
        default { return $code }
    }
}

1;
