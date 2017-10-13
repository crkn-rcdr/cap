package CAP::Controller::Reports;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub index :Path :Args(0) {
    my($self, $c) = @_;
    $c->stash(
        entity => {
            portals => [$c->model('DB::Portal')->list]
        }
    );
    return 1;
}

__PACKAGE__->meta->make_immutable;

1;
