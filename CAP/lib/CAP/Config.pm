package CAP::Config;
use strict;
use warnings;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(as_array as_arrayref);

# Force config file parameters into various constructs.

sub as_array {
    my ($var) = @_;
    return () unless ($var);
    return @{$var} if (ref($var) eq 'ARRAY');
    #return keys(%{$var}) if (ref($var) eq 'HASH');
    return ($var);
}


sub as_arrayref {
    my ($var) = @_;
    return [] unless ($var);
    return $var if (ref($var) eq 'ARRAY');
    #return [keys(%{$var})] if (ref($var) eq 'HASH');
    return [$var];
}



1;
