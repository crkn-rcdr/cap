package CAP::Model::CouchCache;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::CouchCache' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    $parameters->{server} = $app->config->{services}->{cap_caches}->{endpoint};
    return $parameters;
}

1;
