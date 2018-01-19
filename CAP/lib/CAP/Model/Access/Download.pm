package CAP::Model::Access::Download;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::Access::Download' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    return { (%{ $app->config->{services}->{file_access} }, %$parameters) };
}

1;