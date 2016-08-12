package CAP::View::Ajax;

use strict;
use warnings;

use Date::Parse qw(str2time);
use Date::Format qw(time2str);
use Scalar::Util qw(looks_like_number);
use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    STRICT => 1,
    render_die => 1,
    VARIABLES => {
        format_date => sub {
            my $date = shift(@_);
            $date = str2time($date) unless looks_like_number($date);
            return $date ? time2str("%Y-%m-%d", $date) : "";
        },
    }
);

=head1 NAME

CAP::View::Ajax - TT View for CAP

=head1 DESCRIPTION

TT View for CAP.

=head1 SEE ALSO

L<CAP>

=head1 AUTHOR

William Wueppelmann

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
