package CAP::Auth;
use strict;
use warnings;
use Carp;
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use namespace::autoclean;

has 'user' => (is => 'ro');

sub BUILD {
    warn "Building default rule set";
}

__PACKAGE__->meta->make_immutable;

