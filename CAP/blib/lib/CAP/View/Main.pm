package CAP::View::Main;

use strict;
use base 'Catalyst::View::TT';


__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    INCLUDE_PATH => [CAP->path_to('root/Default/templates')],
    WRAPPER => 'main.tt',
    FILTERS => {
        escape_js => sub { $_[0] =~ s/["\\]/\\$1/g; return $_[0]; },
    },
);

=head1 NAME

CAP::View::Default - TT View for CAP

=head1 DESCRIPTION

TT View for CAP. 

=head1 AUTHOR

=head1 SEE ALSO

L<CAP>

William,,,

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
