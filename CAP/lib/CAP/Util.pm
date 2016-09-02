package CAP::Util;
use strict;
use warnings;
use namespace::autoclean;
use Moose;
use MooseX::Method::Signatures;
use Hash::MoreUtils qw/slice_def/;
use Digest::SHA qw(sha1_hex);
use URI;
use Captcha::reCAPTCHA;

has 'c' => (is => 'ro', isa => 'CAP', required => 1);

=head1 CAP::Util - General utility functions

This package is for general utility, helper and macro-type functions.

=head1 Methods

=cut

=head2 build_entity($object)

Build a hashref containing the column names and values of database $object.

=cut
method build_entity ($object) {
    my $entity = {};
    foreach my $column ($object->result_source->columns) {
        $entity->{$column} = $object->get_column($column);
    }
    return $entity;
}


=head2 uri_for_portal ($portal_id, $path)

Calls uri_for($path) and then changes the hostname part of the URL
to the canonical hostname for $portal_id. Returns a URI for the current
portal if the requested portal_id cannot be found. Always sets the
protocol to http.

=cut
method uri_for_portal(Str $portal_id, Str $path) {
    my $uri = $self->c->uri_for($path);
    my $current_hostname = $uri->host;
    $uri->scheme('http');
    my $portal = $self->c->model('DB::Portal')->find({id => $portal_id});
    return $uri if (! $portal);
    my $hostname = $portal->canonical_hostname;
    return $uri if (! $hostname);
    $uri->host($hostname . substr($current_hostname, index($current_hostname, '.')));
    return $uri;
}


=head2 uri_for_secure (@args)

Calls uri_for_action(@args) and then changes the hostname to the secure
portal. Note that protocol is not forced to secure: this should be taken
care of in Model/Secure.pm

=cut
method uri_for_secure(Item @args) {
    my $uri = $self->c->uri_for_action(@args);
    my $host = $self->c->config->{secure}->{host};
    $uri->host($host);
    return $uri;
}

=head2 generate_captcha

Generate captcha HTML code and analyse the result for errors.
Returns a list containing whether or not the captcha request succeeded and the resulting code.

=cut

method generate_captcha {
    my $data = $self->c->req->body_params;
    my $captcha_info = $self->c->config->{captcha};

    # If the keys are configured, then check -- otherwise no
    my $success = 0;
    my $output = "";

    if ($captcha_info->{enabled} && $captcha_info->{publickey} && $captcha_info->{privatekey}) {
        my $captcha = Captcha::reCAPTCHA->new;
        my $error = undef;

        my $rcf = $self->c->request->params->{recaptcha_challenge_field};
        my $rrf = $self->c->request->params->{recaptcha_response_field};

        if ($data->{recaptcha_response_field})  {
            my $captcha_result = $captcha->check_answer(
                $captcha_info->{privatekey},
                $ENV{'REMOTE_ADDR'},
                $data->{recaptcha_challenge_field},
                $data->{recaptcha_response_field});
            if ( $captcha_result->{is_valid} ) {
                $success = 1;
            } else {
                $error = $captcha_result->{error};
            }
        }
        $output = $captcha->get_html($captcha_info->{publickey}, $error, 1, { theme => 'clean', lang => $self->c->stash->{lang} });
    } else {
        # If we aren't checking captcha, give blank html and set success.
        $success = 1;
    }

    return ($success, $output);
}

__PACKAGE__->meta->make_immutable;

1;
