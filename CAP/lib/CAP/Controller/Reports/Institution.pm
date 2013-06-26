package CAP::Controller::Reports::Institution;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

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
    
     my ( $self, $c,$inst ) = @_;

     #stash the name and number of the institution
     $c->stash->{report_inst}       = $inst;
     my $institution                           =  $c->model('DB::Institution')->find({ id => $inst });
    $c->stash->{inst_name}          =  $institution->alias($c->stash->{lang});

    # # Only allow administrators and institution managers to access any of these functions.
    # # Everyone else goes to the login page.
    unless ( $c->user_exists ) {
        redirect_user($c);
        return 1;
    }

     my $user = $c->user->id;
    $c->log->debug("$user is not administrator\n")              unless $c->has_role('administrator');
    $c->log->debug("$user is not institution manager\n") unless $c->model('DB::InstitutionMgmt')->is_inst_manager($user, $inst);

    unless ( $c->has_role('administrator') || $c->model('DB::InstitutionMgmt')->is_inst_manager($user, $inst) )  {
         redirect_user($c);
    }     
 
 }


 
 sub stats: Chained("institution") : PathPart("stats") :  Args(1) {
    
    my ( $self, $c, $portal ) = @_;
  
     $c->stash->{report_portal} = $portal;
     $c->stash->{template} = 'institution.tt';
     show_stats($c, $portal);
 
     return 1;
 
}


sub show_stats {

    my  ($c , $portal_arg) = @_;

    # Build the hashref we send to the template
    $c->stash->{usage_results} = {};

    # Get the institution and portal names
    my $inst_arg                                 =  $c->stash->{'report_inst'};
    $c->stash->{report_portal} =  $portal_arg; 

    # Get date of first log entry
    my $get_start = $c->model('DB::StatsUsageInstitution')->first_month();

    # Get out if there's no data
    return 1 unless ($get_start);

    # Parse the start date
    my $first_entry_date = new Date::Manip::Date;
    my $err              = $first_entry_date->parse($get_start);
    my $first_year       = $first_entry_date->printf("%Y");
    my $first_month      = $first_entry_date->printf("%m");
    $c->stash->{first_month} = $first_month;
    $c->stash->{first_year}  = $first_year;

    # Get the current month and the year
    my $end_date = new Date::Manip::Date;
    $err = $end_date->parse('today');
    my $end_year = $end_date->printf("%Y");

    # Stuff the data into the hashref
    my $month;
    my $year;
    my $first_of_month;
    my $yearly_stats;
    my $monthly_stats;
    my $end_month;
    my $start_month;
    my $current_date;
    
    my $key;
    my $value;
    my $yearly_total;

    for ( $year = $first_year ; $year <= $end_year ; $year++ ) {

        $yearly_stats = [];
        $yearly_total = {
                            searches          => 0,
                            page_views    => 0,
                            sessions          => 0,
                            requests         => 0
         };


        # If we're only reporting on this year we don't need to go all the way to December
        $end_month = ( $year < $end_year ) ? 12 : $end_date->printf("%m");

        # Similarly we don't need to go all the way back to January if we start later
        $start_month = ( $year > $first_year ) ? 1 : $first_month;

        # Iterate through all the months
        for ( $month = $start_month ; $month <= $end_month ; $month++ ) {
            # Parse the date
            $current_date = new Date::Manip::Date;
            $err = $current_date->parse(join('-', ($year, $month, '1')));
            $first_of_month = $current_date->printf("%Y-%m-01");
            
            # Feed monthly totals into arrayref for that year
            $monthly_stats = $c->model('DB::StatsUsageInstitution')->get_stats($inst_arg, $portal_arg, $first_of_month);
            push( @{$yearly_stats}, $monthly_stats );
            
            # Add the monthly totals to the yearly totals
            while(($key, $value) = each(%{$monthly_stats})) {
                $yearly_total->{$key} += $value
            }
        }
        $c->stash->{usage_results}->{$year} = $yearly_stats;
        $c->stash->{yearly_total}->{$year}  = $yearly_total;

    }

}

sub redirect_user {

    my $c = shift();
    $c->session->{login_redirect} = $c->req->uri;
    $c->response->redirect( $c->uri_for( '/user', 'login' ) );
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