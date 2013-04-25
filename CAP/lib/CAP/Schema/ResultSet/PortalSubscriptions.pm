package CAP::Schema::ResultSet::PortalSubscriptions;

use strict;
use warnings;
use base 'DBIx::Class::ResultSet';

=head1 CAP::Schema::ResultSet::PortalsTitles

=head1 Methods

=cut


sub validate {
    my($self, %param) = @_;
    my $valid = 1;
    my @errors = ();

    unless ($param{subscription_id} =~ /^\w{1,32}$/) {
        $valid = 0; push(@errors, 'invalid_subscription_name');
    }
    unless ($param{subscription_level} == 1 || $param{level} == 2) {
        $valid = 0; push(@errors, 'invalid_subscription_level');
    }
    unless ($param{subscription_duration} =~ /^\d+$/ && int($param{subscription_duration} > 0)) {
        $valid = 0; push(@errors, 'invalid_subscription_duration');
    }
    unless ($param{subscription_price} =~ /^\d+(\.\d\d)?$/ && int($param{subscription_price} > 0)) {
        $valid = 0; push(@errors, 'invalid_subscription_price');
    }

    return { valid => $valid, errors => \@errors }
}

1;

