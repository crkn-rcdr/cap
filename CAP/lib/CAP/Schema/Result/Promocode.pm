package CAP::Schema::Result::Promocode;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "EncodedColumn");

=head1 NAME

CAP::Schema::Result::Promocode

=cut

__PACKAGE__->table("promocode");

=head1 ACCESSORS

=head2 id

  data_type: 'varchar'
  is_nullable: 0
  size: 32

=head2 expires

  data_type: 'datetime'
  is_nullable: 1

=head2 amount

  data_type: 'decimal'
  is_nullable: 0
  size: [10,2]

=cut

__PACKAGE__->add_columns(
  "id",
  { data_type => "varchar", is_nullable => 0, size => 32 },
  "expires",
  { data_type => "datetime", is_nullable => 1 },
  "amount",
  { data_type => "decimal", is_nullable => 0, size => [10, 2] },
);
__PACKAGE__->set_primary_key("id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2011-12-12 11:57:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:4WpeTLyPSlTQ8m/flo/VRQ

sub expired {
    my $self = shift;
    return ($self->expires->epoch <= time) ? 1 : 0;
}
1;
