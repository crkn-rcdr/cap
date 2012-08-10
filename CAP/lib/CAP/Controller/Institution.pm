package CAP::Controller::Institution;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

BEGIN {extends 'Catalyst::Controller'; }

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

sub auto :Private {
    my($self, $c) = @_;

    # Require SSL for all operations
    $c->require_ssl;

    # Only allow administrators to access any of these functions. Everyone
    # else gets a 404.
    unless ($c->has_role('administrator')) {
        $c->session->{login_redirect} = $c->req->uri;
        $c->response->redirect($c->uri_for('/user', 'login'));
        return 0;
    }

    return 1;
}



sub index :Path :Args(1) {
    my ( $self, $c ) = @_;

    # Get date of first log entry
    # To do: grab date range from query string
    my $first_entry_date     = $c->model('DB::RequestLog')->get_start();   
    my $first_year           = $first_entry_date->{local_c}->{year};
    my $first_month          = $first_entry_date->{local_c}->{month};
    $c->stash->{first_month} = $first_month;
    $c->stash->{first_year}  = $first_year;
    
    #Get the institution name
    my $inst_arg             = $c->request->arguments->[0];
    my $inst_name            = $c->model('DB::Institution')->get_name($inst_arg);
    $c->stash->{report_inst} = $inst_name;

    # Get the current month and the year
    my $end_date  = new Date::Manip::Date;
    my $err       = $end_date->parse('today');
    my $end_year  = $end_date->printf("%Y");
   
    my $month;
    my $year;
    
    $c->stash->{usage_results} = {};
    
    for ($year = $first_year; $year <= $end_year; $year++) {
    
        my $yearly_stats = [];
    
        # If we're only reporting on this year we don't need to go all the way to December
        my $end_month = ($year < $end_year) ? 12 : $end_date->printf("%m");
        
        # Similarly we don't need to go all the way back to January if we start later
        my $start_month = ($year > $first_year) ? 1 : $first_month ;        

        # Iterate through all the months
        for ($month = $start_month; $month <= $end_month; $month++) {
            push(@{$yearly_stats}, $c->model('DB::RequestLog')->get_monthly_stats($inst_arg, $month, $year));
        };
        $c->stash->{usage_results}->{$year} = $yearly_stats;
        
    }
    
    $c->stash->{template} = 'institution.tt';
    return 1;
}


=head1 AUTHOR

Milan Budimirovic,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
