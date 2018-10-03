package CAP::Controller::Mail;
use Moose;
use namespace::autoclean;

use File::MimeInfo;
use File::Basename;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

CAP::Controller::Mail - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 sendmail

=cut

sub sendmail {
    my ($self, $c, $template, $header, $attach) = @_;

    my $old_template_paths = $c->stash->{additional_template_paths};
    $c->stash(additional_template_paths => [
        join('/', $c->config->{root}, 'templates', 'Mail', $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', 'Mail', 'Common'),
        join('/', $c->config->{root}, 'templates', 'Default', $c->stash->{portal}),
        join('/', $c->config->{root}, 'templates', 'Default', 'Common')
    ]);


    if (defined($attach)) {
	# Assumes a single file name. Will need update if we want to 
        # accept array of filenames

	my $attachtype = mimetype($attach);
	my $attachbody = "";
	local $/ = undef;
	if (open FILE, $attach) {
	    binmode FILE;
	    $attachbody = <FILE>;
	    close FILE;
	} else {
        $c->stash(additional_template_paths => $old_template_paths);
	    return 1;
	}

	my $textbody = $c->view("Mail")->render($c, $template);

	# Two part MIME message:  plain text + attachment
	my @parts = (
	    Email::MIME->create (
		attributes => {
		    content_type => 'text/plain',
		    charset      => 'UTF-8',
		},
		body => $textbody,
	    ),
	    Email::MIME->create(
		attributes => {
		    content_type => $attachtype,
		    encoding     => 'base64',
		    name         => basename($attach),
		},
		body => $attachbody,
	    ),
	);

	$c->email({
		header => $header,
		parts => \@parts,
	    });

    }
    
    else {
	# Send simple email
	
	$c->email({
		header => $header,
		body => $c->view("Mail")->render($c, $template)
	    }) or die "could not send mail";
    }
    $c->stash(additional_template_paths => $old_template_paths);
    return 1;
}

sub status_report :Private {
    my($self, $c, $recipients, %data) = @_;

    my $header = [
        'From'                                                 =>  $c->config->{email_from},
        'To'                                                        => $recipients,
        'Subject'                                            => $c->loc("CAP System Status Report"),
        'Content-Transfer-Encoding'  =>  '8bit',
        'Content-Type'                                => 'text/html; charset="UTF8"'
    ];
    $c->stash(mail_data => {%data});
    $self->sendmail($c, 'status_report.tt', $header);
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
