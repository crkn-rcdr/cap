package CAP::Controller::Reports::Content;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Reports::Content - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ($self, $c) = @_;
    my $params = {};
    $params->{time} = { '<=' => $c->stash->{end}, '>=' => $c->stash->{start} };
    $params->{portal_id} = $c->stash->{limit_portal}->id if ($c->stash->{limit_portal});

    my $result = $c->model('DB::TitleViews')->search(
        $params,
        {
            select => [ 'title_id', { count => { distinct => 'session' }, -as => 'count' } ],
            as => [ 'title_id', 'count' ],
            group_by => [ 'title_id' ],
            order_by => { -desc => 'count' },
            rows => 100
        }
    );

    my $entity = [];
    while (my $record = $result->next) {
        my $title = $c->model('DB::Titles')->find($record->title_id);
        push(@{$entity}, { count => $record->get_column('count'), title => $title });
    }

    $c->stash->{entity} = $entity;
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
