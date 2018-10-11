package CAP::Portal;

use utf8;
use strictures 2;

use Moose;
use namespace::autoclean;

extends 'CAP::Collection';

has 'search' => (
    is => 'ro',
    isa => 'Bool',
    required => 1,
    default => 1
);

has 'subcollections' => (
    is => 'ro',
    isa => 'HashRef',
    default => sub { {} },
    writer => '_set_subcollections'
);

sub has_subcollections {
    my ($self) = @_;
    return scalar keys %{ $self->subcollections };
}

sub subcollection_labels {
    my ($self, $lang) = @_;
    return { map {
        $_ => $self->subcollections->{$_}->label->{$lang}
    } keys %{ $self->subcollections } };
}

sub sorted_subcollection_keys {
    my ($self, $lang) = @_;
    my $labels = $self->subcollection_labels($lang);
    return [ sort { $labels->{$a} cmp $labels->{$b} } keys %$labels ];
}

1;
