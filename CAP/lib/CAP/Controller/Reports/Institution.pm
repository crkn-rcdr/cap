package CAP::Controller::Reports::Institution;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::ActionRole'; }


=head1 NAME

CAP::Controller::Institution - Catalyst Controller

=head1 DESCRIPTION

CAP Catalyst controller module for usage reporting

=head1 METHODS
=item index
Queries the request_log table and stashes a hashref of user stats for a given institution

=cut

=head2 index

=cut



sub institution : Chained("/") : PathPart("reports/institution") : CaptureArgs(1) {
    my ($self, $c, $id) = @_;

    $c->stash->{report_institution_id} = $id;
    my $institution = $c->model('DB::Institution')->find($id);
    $c->stash->{report_institution_name} = $institution ? $institution->alias($c->stash->{lang}) : '?';

    # # Only allow administrators and institution managers to access any of these functions.
    # # Everyone else goes to the login page.
    my $can_access = $c->has_role('administrator, reports') || $c->model('DB::InstitutionMgmt')->is_inst_manager($c->user->id, $id);
    unless ($c->user_exists && $can_access) {
        redirect_user($c);
        return 1;
    }  
}
 
sub stats: Chained("institution") : PathPart("stats") :  Args(1) {
    my ($self, $c, $portal) = @_;

    if ($portal eq 'total') {
        $c->stash->{report_portal_name} = $c->loc('All Portals');
    } else {
        my $portal_entry = $c->model('DB::Portal')->find($portal);
        $c->stash->{report_portal_name} = $portal_entry ? $portal_entry->title($c->stash->{lang}) : '?';
    }
    $c->stash->{stats} = $c->model('UsageStats')->retrieve($c->stash->{lang}, $portal, 'institution', $c->stash->{report_institution_id});
  
    return 1;
}

sub redirect_user {

    my $c = shift();
    #$c->session->{login_redirect} = $c->req->uri;
    $c->response->redirect( $c->uri_for( '/user', 'login' ) );
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
