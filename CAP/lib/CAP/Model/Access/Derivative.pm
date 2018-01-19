package CAP::Model::Access::Derivative;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::Access::Derivative' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    return +{ (%{ $app->config->{services}->{iiif_image} }, %$parameters) };
}

1;
