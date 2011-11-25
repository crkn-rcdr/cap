package CAP::Controller::Mail;
use Moose;
use namespace::autoclean;

BEGIN {extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Mail - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 sendmail

=cut

sub sendmail {
    my ($self, $c, $template, $header) = @_;

    $c->stash(additional_template_paths => [
        join('/', $c->config->{root}, 'templates', 'Mail', $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', 'Mail', 'Common')
    ]);

    $c->email(
        {
            header => $header,
            body => $c->view("Mail")->render($c, $template)
        }
    );

    return 1;
}

sub user_reset :Private {
    my ($self, $c, $recipient, $confirm_link) = @_;
    $c->stash(confirm_link => $confirm_link);
    my $header = [
        From => 'info@canadiana.ca',
        To => $recipient,
        Subject => $c->loc('Password Reset')
    ];

    $self->sendmail($c, "reset.tt", $header);
    return 1;
}

sub user_activate :Private {
    my ($self, $c, $recipient, $real_name, $confirm_link) = @_;
    $c->stash(recipient => $recipient,
        real_name => $real_name,
        confirm_link => $confirm_link
    );

    my $header = [
        From => 'info@canadiana.ca',
        To => $recipient,
        Subject => $c->loc('ECO Account Activation')
    ];

    $self->sendmail($c, "activate.tt", $header);
    return 1;
}

sub subscription_notice :Private {
    my ($self, $c, $admins, $success, $oldexpire, $newexpire, $message) = @_;
    $c->stash(subscribe_success => $success,
        subscribe_oldexpire => $oldexpire,
        subscribe_newexpire => $newexpire,
        subscribe_message => $message
    );

    my $header = [
        From => 'info@canadiana.ca',
        To => $admins,
        Subject => $c->loc('ECO Subscription Finalized')
    ];

    $self->sendmail($c, "subscribe_finalize.tt", $header);
    return 1;
}

=head1 AUTHOR

Sascha Adler,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;