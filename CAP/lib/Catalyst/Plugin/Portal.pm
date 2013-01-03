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

$c->set_portal;
my $portal = $c->portal;

=back

=cut

__PACKAGE__->mk_accessors(qw/portal/);

=head2 set_portal

Determine which portal to use and configure it. If no valid and enabled
portal is found, redirect to a default location.

=cut
sub set_portal {
    my($c) = @_;
    my $host = substr($c->req->uri->host, 0, index($c->req->uri->host, '.'));
    my $portal =  $c->model('DB::PortalHost')->get_portal($host);
    $c->portal($portal);
    unless ($c->portal && $c->portal->enabled) {
        $c->res->redirect($c->config->{default_url});
        $c->detach();
    }
}

1;
