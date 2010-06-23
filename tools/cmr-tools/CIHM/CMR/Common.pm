package CIHM::CMR::Common;

use strict;
use warnings;
use feature qw(switch);

use Exporter qw(import);
our @EXPORT = qw(each_element element iso8601 media_mime normalize_space translate);

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

    # YYYY-MM-DDTHH:MM:SSZ
    if ($date =~ /(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2})Z/) {
        return $1 . substr($template, length($1));
    }

    # Date in the form YYYY-MM-DD
    if ($date =~ /^\d{4}-\d{2}-\d{2}$/) {
        return $date . substr($template, length($date));
    }

    # Date in the form YYYY, possibly with junk preceding or following
    if ($date =~ /\b(\d{4})\b/) {
        return $1 . substr($template, length($1));
    }

    return undef;
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

