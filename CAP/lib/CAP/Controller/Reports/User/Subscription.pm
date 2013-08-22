package CAP::Controller::Reports::User::Subscription;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller::REST'; }
__PACKAGE__->config( default => 'text/html', map => { 'text/html' => [ 'View', 'Default' ] });

=head1 NAME

CAP::Controller::Reports::User::Subscription - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


sub auto :Private {
    my($self, $c) = @_;
    my $data = $c->req->params;
    my $start;
    my $end;
    my $portal;

    # Set the reporting period. The default end date is now and the
    # default start date is 30 days before the end date.
    if ($data->{end}) {
        my($year, $month, $day) = split(/-/, $data->{end});
        $end = DateTime->new({ year => $year, month => $month, day => $day});
    }
    else {
        $end = DateTime->now();
    }

    if ($data->{start}) {
        my($year, $month, $day) = split(/-/, $data->{start});
        $start = DateTime->new({ year => $year, month => $month, day => $day});
    }
    else {
        #$start = $end->clone->subtract(DateTime::Duration->new(days => 30));
        $start = $end->clone;
        $start->subtract(DateTime::Duration->new(days => 30));
    }

    # Limit by portal, if one is defined
    if ($data->{portal}) {
        $portal = $c->model('DB::Portal')->find($data->{portal});
    }

    $c->stash(
        start => $start,
        end => $end,
        limit_portal => $portal
    );

    return 1;
}

=head2 index

Summarize all subscriptions over the reporting period

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;
    my $params = {};
    $params->{completed} = { '<=' => $c->stash->{end}, '>=' => $c->stash->{start} };
    $params->{portal_id} = $c->stash->{limit_portal}->id if ($c->stash->{limit_portal});

    my $entity = $c->model('DB::Subscription')->search($params);
    $c->stash(
        entity => [$entity->all],
        metrics => $c->model('DB::Subscription')->metrics($entity),
        portals => [$c->model('DB::Portal')->list]
    );
    return 1;
}



=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
