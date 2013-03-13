package Catalyst::Plugin::Util;
use strict;
use warnings;
use Moose;
use MRO::Compat;

with 'MooseX::Emulate::Class::Accessor::Fast';

=head1 Catalyst::Plugin::Institution

Provide access to the institution as a context object accessor.

=head2 Usage

=over 4

$c->get_institution;
my $institution = $c->institution;

=back

=cut

__PACKAGE__->mk_accessors(qw/cap/);

=head2 set_portal

Set the institution, if one is associated with the request.

=cut
sub set_util {
    my($c) = @_;
    $c->cap(new CAP::Util(c => $c));
}

1;

