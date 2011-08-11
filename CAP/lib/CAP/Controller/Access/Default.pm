package CAP::Controller::Access::Default;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

sub has_access :Private {
    my ($self, $c, $doc, $key, $resource_type, $size) = @_;
    return 1;
}

sub access_level :Private {
    my ($self, $c, $doc) = @_;
    return 1;
}

__PACKAGE__->meta->make_immutable;

