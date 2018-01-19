package CAP::Model::Access::Search;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::Access::Search' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    $parameters->{server} = $app->config->{services}->{cosearch}->{endpoint};
    return $parameters;
}

1;