package CAP::Collection;

use utf8;
use strictures 2;

use Moose;
use namespace::autoclean;

has 'id' => (
    is => 'ro',
    required => 1,
    isa => 'Str'
);

has 'label' => (
    is => 'ro',
    required => 1,
    isa => 'HashRef[Str]'
);

has 'summary' => (
    is => 'ro',
    isa => 'HashRef[Str]'
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    my $hash = $class->$orig(@args);

    foreach my $arg (qw/label summary/) {
        if ($hash->{$arg}) {
            foreach my $lang (keys %{ $hash->{$arg} }) {
                if (ref $hash->{$arg}->{$lang} eq 'ARRAY') {
                    $hash->{$arg}->{$lang} = join(' ', @{ $hash->{$arg}->{$lang} });
                }
            }
        }
    }

    return $hash;
};

1;
