package CAP::Controller::Reports::Links;
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

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    my $period = 30;
    if ($c->req->params->{period}) {
        $period = int($c->req->params->{period});
    }
    $c->stash(
        period          => $period,
        referral_report => $c->model('DB::OutboundLink')->referral_report($period),
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
