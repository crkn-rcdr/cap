package CAP::Model::UsageStats;

use base 'Catalyst::Model::Adaptor';
__PACKAGE__->config( class => 'CIHM::UsageStats' );

sub prepare_arguments {
    my ($self, $app, $arg) = @_;
    my $parameters = exists $self->{args} ? {
        %{$self->{args}},
        %$arg,
    } : $arg;
    $parameters->{statsdb} = $app->config->{services}->{usage_stats}->{endpoint};
    $parameters->{logfiledb} = $app->config->{services}->{usage_logfile_registry}->{endpoint};
    return $parameters;
}

1;