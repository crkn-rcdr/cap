package Catalyst::Plugin::Auth;
use strict;
use warnings;
use Moose;
use MRO::Compat;
use CAP::Auth;

with 'MooseX::Emulate::Class::Accessor::Fast';

=head1 Catalyst::Plugin::Auth

Context-level access to an authorization object

=head2 Usage

=over 4

$c->set_portal;
my $portal = $c->portal;

=back

=cut

__PACKAGE__->mk_accessors(qw/auth/);

=head2 set_auth

=cut
sub set_auth {
    my($c) = @_;
    my $auth = CAP::Auth->new($c->portal, $c->institution, $c->user);
    $c->auth($auth);
}

1;

