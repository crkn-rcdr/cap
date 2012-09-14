package Catalyst::Plugin::Institution;
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

__PACKAGE__->mk_accessors(qw/institution/);

sub get_institution {
    my($c) = @_;
    my $host = substr($c->req->uri->host, 0, index($c->req->uri->host, '.'));
    my $institution = $c->model('DB::InstitutionIpaddr')->institution_for_ip($c->req->address);
    $c->institution($institution);
}

1;

