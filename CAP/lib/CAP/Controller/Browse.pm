package CAP::Controller::Browse;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

sub auto : Private {
  my ( $self, $c ) = @_;

  unless ( $c->portal_id eq 'parl' ) {
    $c->detach( '/error', [404, "Browsing from a non-parl portal"] );
  }
}

sub index : Path : Args(0) {
  my ( $self, $c ) = @_;

  $c->stash(
    tree          => $c->model('Parl')->tree(),
    parl_sessions => $c->model('ParlSession')->all()
  );

  return 1;
}

sub leaf_without_session : Path : Args(3) {
  my ( $self, $c, $language, $chamber, $type ) = @_;

  my $leaf = $c->model('Parl')->leaf( $language, $chamber, $type );
  $c->stash(
    leaf          => $leaf->{leaf},
    title         => $leaf->{title},
    parl_language => $language,
    parl_chamber  => $chamber,
    parl_type     => $type,
    template      => 'browse/leaf.tt'
  );
}

sub leaf : Path : Args(4) {
  my ( $self, $c, $language, $chamber, $type, $session ) = @_;

  my $leaf = $c->model('Parl')->leaf( $language, $chamber, $type, $session );
  my $session_doc = $c->model('ParlSession')->session($session);
  $c->stash(
    leaf            => $leaf->{leaf},
    title           => $leaf->{title},
    parl_language   => $language,
    parl_chamber    => $chamber,
    parl_type       => $type,
    parl_session    => $session_doc,
    parl_parliament => substr $session_doc->{_id},
    0, 2
  );

  return 1;
}
__PACKAGE__->meta->make_immutable;

1;
