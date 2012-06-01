package CAP::Controller::Institution;
use Moose;
use namespace::autoclean;
use Date::Manip::Date;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Institution - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(1) {
    my ( $self, $c ) = @_;

    # $c->response->body('Matched CAP::Controller::Institution in Institution.');

    my $inst_arg = $c->request->arguments->[0];
    my $inst_name = $c->model('DB::Institution')->get_name($inst_arg);
    $c->stash->{report_inst} = $inst_name;
    $c->stash->{template} = 'institution.tt';
    
    # Get the current month and the year
    my $end_date = new Date::Manip::Date;
    my $err = $end_date->parse('today');
    my $end_month = $end_date->printf("%m");
    my $end_year  = $end_date->printf("%Y");

    # Get the current (as in the one we're parsing at any give time) month and the year
    my $current_date = new Date::Manip::Date;
    my $current_date_str = "January 1, " . $end_year;
    $err = $current_date->parse($current_date_str);
    my $start_month = $current_date->printf("%m");

    
    my $month;
    my $year  = $end_year;
    
    $c->stash->{usage_results} = {};
    
    my $yearly_stats = [];
    
    # Iterate through all the months
    for ($month = $start_month; $month <= $end_month; $month++) {
        $current_date->set('m',$month);
        # my $month_name = $current_date->printf("%B");
        push($yearly_stats, $c->model('DB::RequestLog')->get_monthly_stats($inst_arg, $month, $year));
    };
    $c->stash->{usage_results}->{$year} = $yearly_stats;
    
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
