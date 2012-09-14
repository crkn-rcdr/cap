package Catalyst::Plugin::Portal;
use strict;
use warnings;
use Moose;
use MRO::Compat;

with 'MooseX::Emulate::Class::Accessor::Fast';

=head1 Catalyst::Plugin::Portal

Provide access to the portal as a context object accessor.

=head2 Usage

=over 4

$c->configure_portal;
my $portal = $c->portal;

=back

=cut

__PACKAGE__->mk_accessors(qw/portal/);

sub configure_portal {
    my($c) = @_;
    my $host = substr($c->req->uri->host, 0, index($c->req->uri->host, '.'));
    my $portal =  $c->model('DB::PortalHost')->get_portal($host);
    $c->portal($portal);
}

1;
