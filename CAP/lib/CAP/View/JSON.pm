package CAP::View::JSON;
use JSON;

use strict;
use warnings;

use base 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    STRICT => 1,
    render_die => 1,
);

=head1 NAME

CAP::View::JSON - TT View for CAP

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
