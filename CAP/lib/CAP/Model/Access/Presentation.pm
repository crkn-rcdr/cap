package CAP::Model::Access::Presentation;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::Access::Presentation' );

sub prepare_arguments {
  my ( $self, $app, $arg ) = @_;
  my $parameters =
    exists $self->{args} ? { %{ $self->{args} }, %$arg, } : $arg;
  $parameters->{download}   = $app->model('Access::Download');
  return $parameters;
}
1;