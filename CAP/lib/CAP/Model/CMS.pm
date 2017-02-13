package CAP::Model::CMS;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::CMS' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    $parameters->{languages} = $app->config->{languages};
    $parameters->{cache} = $app->model('CouchCache');
    return $parameters;
}

1;