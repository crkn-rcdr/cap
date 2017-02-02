package CAP::Controller::Reports::Portal;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Reports::Links - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(1) {
    my ($self, $c, $portal) = @_;
    
    # Users with the admin or reports role may access these func tions. Everyone
    # else gets 404ed or redirected to the login page.
    # Authorization for institution stats is done further down the food chain
    unless ($c->has_role('administrator', 'reports')) {
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    if ($portal eq 'total') {
        $c->stash->{report_portal_name} = $c->loc('All Portals');
    } else {
        my $portal_entry = $c->model('DB::Portal')->find($portal);
        $c->stash->{report_portal_name} = $portal_entry ? $portal_entry->title($c->stash->{lang}) : '?';
    }
    $c->stash->{stats} = $c->model('UsageStats')->retrieve($c->stash->{lang}, $portal, 'portal');

    return 1;
}

=head1 AUTHOR

Sascha Adler

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
