package CIHM::CMR::Filters;

use strict;
use warnings;
use feature qw(switch);
use Date::Manip;
use utf8;

use Exporter qw(import);
our @EXPORT = qw(each_element element iso8601 media_mime normalize_space translate);

my $DEBUG = 0;  # Output extended debugging information to stderr
my $FAILED = 1; # Output notices of failure to find a date to stderr

# Evaluate and convert a date to a full ISO-8601 date string. If not
# possible, return undef. If $max is true, returns the greatest matching
# date; otherwise returns the minimum. (E.g.: 1980 will return
# 1980-12-31T23:59:59.999Z if $max is true and 1980-01-01T00:00:00.000Z
# otherwise.)
sub iso8601
{
    my($date, $max) = @_;
    my $template = "0001-01-01T00:00:00.000Z";
    $template = "9999-12-31T23:59:59.999Z" if ($max);

    # If we already have an unambiguous ISO-8601 date, don't mess around
    # with it. The following formats should be accepted:
    # YYYY
    # YYYY-MM-DD
    # YYYY-MM-DDTHH:MM:SS
    # YYYY-MM-DDTHH:MM:SS.sss
    # YYYY-MM-DDTHH:MM:SS.sssZ
    if ($date =~ /^(\d{4}(-\d{2}-\d{2}(T\d{2}:\d{2}:\d{2})?(\.\d{3}(Z)?)?)?)$/) {
        return $1 . substr($template, length($1));
    }

    # Remove some characters that we never want to see
    $date =~ s/[\[\]\.\`]//g;

    # The pattern ####-## is ambiguous, but we will assume it is a year
    # range, so we intercept it here.
    if($date =~ /^\s*(\d{2})(\d{2})\s*-\s*(\d{2})\s*$/) {
        if ($2 < $3) {
            return sprintf("%02d%02d-12-31T23:59:59.999Z", $1, $3) if ($max);
            return sprintf("%02d%02d-01-01T00:00:00.000Z", $1, $2);
        }
        else {
            return sprintf("%02d%02d-12-31T23:59:59.999Z", $1 + 1, $3) if ($max);
            return sprintf("%02d%02d-01-01T00:00:00.000Z", $1, $2);
        }
    }

    # Translate French month names into English
    $date =~ s/\bjanvier\b/January/i;
    $date =~ s/\bfévrier\b/February/i;
    $date =~ s/\bmars\b/March/i;
    $date =~ s/\bavril\b/April/i;
    $date =~ s/\bmai\b/May/i;
    $date =~ s/\bjuin\b/June/i;
    $date =~ s/\bjuillet\b/July/i;
    $date =~ s/\baoût\b/August/i;
    $date =~ s/\bseptembre\b/September/i;
    $date =~ s/\boctobre\b/October/i;
    $date =~ s/\bnovembre\b/November/i;
    $date =~ s/\bdécembre\b/December/i;

    # And some abbreviations
    $date =~ s/\bjanv/Jan/i;
    $date =~ s/\bfév(r)?/Feb/i;
    $date =~ s/\bjuil/Jul/i;
    $date =~ s/\bdéc/Dec/i;

    # And unbreak abbreviations like '75 (assuming 1900s)
    $date =~ s/\s+'(\d{2})(?:\b|$)/19$1/;

    # If we can parse this date using Date::Manip, create an ISO8601 date.
    # Eliminate any January 1st dates or 1st of the month dates, because
    # these might just be the defaults and not the actual date.
    my $parsed_date = ParseDate($date);
    if ($parsed_date) {
        warn("Parsed date: $date = $parsed_date") if ($DEBUG);
        $date = UnixDate($date, "%Y-%m-%d");
        $date =~ s/-01-01$//;
        $date =~ s/-01$//;
    }

    # Otherwise, try to parse out the date based on some common AACR2 date
    # conventions.
    else {
        warn ("iso8601: trying to match $date") if ($DEBUG);

        $date =~ s/l/1/g; # Ocassionally, "1" is mistyped as "l" (OCR issue?)

        # Some patterns we want to reuse
        my $ST = '(?:^|\b)';  # start of word or string
        my $CA = '(?:^|\b|c|ca|circa|e)'; # start of word, string, or c/ca/circa/e (F and E abbr's for circa)
        my $HY = '\s*-\s*';   # hyphen/dash with or without spaces
        my $EN = '(?:\b|$)';  # end of word or string

        $date = lc($date);      # and normalize the case

        if (0) {
        }

        # Eg 190?, 19?? 1???
        elsif ($date =~ /$ST(\d)\?\?\?EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}999" }
            else {$date = "${1}000" }
        }
        elsif ($date =~ /$ST(\d{2})\?\?EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}99" }
            else { $date = "${1}00" }
        }
        elsif ($date =~ /$ST(\d{3})\?$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}9" }
            else { $date = "${1}0" }
        }

        # E.g. 1903-1904
        elsif ($date =~ /$ST(\d{4})$HY(\d{4})$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = $2 }
            else { $date = $1 }
        }

        # E.g. 1918-19; 1990-01, c.1923-24 (treat as: 1990-2001)
        elsif ($date =~ /$ST(?:$CA)?(\d{2})(\d{2})$HY(\d{2})$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($3 > $2) {
                if ($max) { $date = "$1$3" } else { $date = "$1$2" }
            }
            else {
                if ($max) { $date = "$1$2" } else { $date = sprintf("%2d%2d", $1 + 1, $3) }
            }
        }

        # E.g. 1903-4, c.1910-1
        elsif ($date =~ /$ST(?:$CA)?(\d{3})(\d{1})$HY(\d{1})$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($3 > $2) {
                if ($max) { $date = "$1$3" } else { $date = "$1$2" }
            }
            else {
                if ($max) { $date = "$1$2" } else { $date = sprintf("%3d%1d", $1 + 1, $3) }
            }
        }

        # E.g. 192-, 192-?, 19-, 19-?, c185-?, etc.
        elsif ($date =~ /$ST(?:$CA)?(\d{3})$HY/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}9" } else { $date = "${1}0" }
        }
        elsif ($date =~ /$ST(?:$CA)?(\d{2})$HY/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}99" } else { $date = "${1}00" }
        }

        # E.g. c1912- (this is bad form but occasionally appears)
        elsif ($date =~ /$ST(?:$CA)?(\d{4})$HY$/) {
            warn "iso8601: matched $date" if ($DEBUG);
            $date = $1;
        }

        # E.g.: 1900s; 1920s; 1920's; c.1920's
        elsif ($date =~ /$CA(\d{2})00(?:')?s/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}99" } else { $date = "${1}00" }
        }
        elsif ($date =~ /$CA(\d{3})0(?:')?s/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}9" } else { $date = "${1}0" }
        }

        # E.g. c.1920 or ca.1920, e1949
        elsif ($date =~ /$CA?\s*(\d{4})$/) {
            warn "iso8601: matched $date" if ($DEBUG);
            $date = $1;
        }

        # E.g. ca. 192, 192 (instead of ca. 1920s)
        elsif ($date =~ /^(?:$CA)?(\d{3})$/) {
            warn "iso8601: matched $date" if ($DEBUG);
            if ($max) { $date = "${1}9" } else { $date = "${1}0" }
        }

        # E.g. 2-6-98 or 1-1-1998: we don't know which is the month, but
        # we can get the year.
        # TODO: if one of the numbers is > 12, then we can get the month
        # and year.
        elsif ($date =~ /$ST\d+-\d+-(\d{2})$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            $date = "19$1";
        }
        elsif ($date =~ /$ST\d+-\d+-(\d{4})$EN/) {
            warn "iso8601: matched $date" if ($DEBUG);
            $date = $1;
        }

        # E.g.: early 20th century; late 20th century
        elsif ($date =~ /early (\d{2})th century/i) {
            warn "iso8601: matched $date" if ($DEBUG);
            my $yy = ${1} - 1;
            if ($max) { $date = "${yy}30" } else { $date = "${yy}00" }
        }
        elsif ($date =~ /late (\d{2})th century/i) {
            warn "iso8601: matched $date" if ($DEBUG);
            my $yy = ${1} - 1;
            if ($max) { $date = "${yy}70" } else { $date = "${yy}99" }
        }

        # No numerical characters at all
        elsif ($date !~ /\d/) {
            warn("iso8061: failed to match $date") if ($DEBUG);
            return "";
        }
    }

    warn("iso8601: processing $date") if ($DEBUG);

    # YYYY-MM-DDTHH:MM:SSZ
    # TODO: do we still need this?
    if ($date =~ /(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})Z/) {
        return $1 . substr($template, length($1));
    }

    # Date in the form YYYY-MM-DD
    if ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
        return $date . substr($template, length($date));
    }

    # Date in the form YYYY-MM
    if ($date =~ /^\d{4}-(\d{2})$/) {
        # Adjust the template so that we have a legal end date.
        given ($1) {
            when (/01|03|05|07|08|10|12/) { ; }
            when (/04|06|09|11/) { $template =~ s/-31T/-30T/; }
            when ("02")          { $template =~ s/-31T/-28T/; }
        }
        return $date . substr($template, length($date));
    }

    # Date in the form YYYY, possibly with junk preceding or following
    if ($date =~ /\b(\d{4})\b/) {
        return $1 . substr($template, length($1));
    }

    warn("iso8601: null date for $date") if ($DEBUG || $FAILED);
    return "";
    #return $date;
}

sub media_mime
{
    my($mime) = @_;
    given ($mime) {
        when ('audio/mp3') { return 'sound' }
        default            { return "" }
    }
}

sub normalize_space
{
    my($string) = @_;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    $string =~ s/\s+/ /g;
    return $string;
}


# Create an element called $element_name with the attribute-value pairs in
# $attributes. If $text is specified, it will be added as a text node
# child of the element. If $parent is defined, the new element will be
# appended as a child of that element. Returns a reference to the
# newly-created element. If $noempty is true and $text is undefined or the
# empty string, the element is not appended or returned.
sub element
{
    my($doc, $parent, $element_name, $attributes, $text, $noempty) = @_;
    my $element = $doc->createElement($element_name);
    while (my($attribute, $value) = each(%{$attributes})) {
        $element->setAttribute($attribute, $value) if ($value);
    }
    if ($text) {
        $element->appendChild($doc->createTextNode($text));
    }
    elsif ($noempty) {
        return undef;
    }
    if ($parent) {
        $parent->appendChild($element);
    }
    return $element;
}

sub translate
{
    my($string, $table) = @_;
    return $table->{$string} if ($table->{$string});
    return $string;
}

1;
