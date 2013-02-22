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

sub index :Path :Args(2) {
    my ($self, $c) = @_;
    

    my $portal = defined ( $c->portal->id ) ? $c->portal->id : 'eco';

    # Get some action
    my $action = $c->request->arguments->[1];
    my $portal = $c->request->arguments->[0];
    $c->log->error("action is $action : $!\n");
    
#     $c->stash->{template} = 'portal_stats.tt';

    if ( $action eq 'stats' ) {
        # $c->stash->{template} = 'portal_stats.tt';
        show_stats($c, $portal);
    }

    else {
        redirect_user($c);
    }

    return 1;
}

sub show_stats {

    my ($c, $portal) = @_;

    # Build the hashref we send to the template
    $c->stash->{usage_results} = {};



    # Get date of first log entry
    my $get_start = $c->model('DB::StatsUsagePortal')->first_month();

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
                            searches     => 0,
                            page_views   => 0,
                            sessions     => 0,
                            requests     => 0
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
            $monthly_stats = $c->model('DB::StatsUsagePortal')->get_stats($portal, $first_of_month);
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

Milan Budimirovic

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
