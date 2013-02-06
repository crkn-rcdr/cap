package CAP::Util::Export;

use strict;
use warnings;
use feature qw(switch);
use Moose;
use Moose::Util::TypeConstraints;
use MooseX::Method::Signatures;
use JSON;

has 'c'      => (is => 'ro', isa => 'CAP', required => 1);
has 'data'   => (is => 'ro', isa => 'HashRef');
has 'tables' => (is => 'ro', isa => 'ArrayRef');

method BUILD {
    $self->{data} = {};

    # Tables must be exported in the following order due to key
    # dependencies.
    $self->{tables} = [qw(
        Collections
        Portals
        PortalCollection
        PortalFeature
        PortalLang
        PortalHost
        PortalString
        PortalSupport

        Language
        MediaType
        Role
        DocumentCollection
        DocumentThesaurus
        Thesaurus
    )];
}

method add (Str $set) {
    given ($set) {
        when ('base') {
            $self->_export_general('Role');
            $self->_export_general('Portal');
            $self->_export_general('Collection');
            $self->_export_general('PortalCollection');
            $self->_export_general('PortalFeature');
            $self->_export_general('PortalLang');
            $self->_export_general('PortalHost');
            $self->_export_general('PortalString');
            $self->_export_general('PortalSupport');
            $self->_export_general('MediaType');
        }
        default             { $self->_export_general($set) };
    }
}

method import_data (Str $file) {
    open(JSON, "<$file") or die("Cannot open file '$file' for reading: $!");
    my $data = decode_json(join("", <JSON>));
    close(JSON);

    foreach my $table (@{$data}) {
        given ($table->[0]) {
            when ('Thesaurus')  { $self->_import_replace($table) };
            default             { $self->_import_general($table) };
        }

    }
}

method export () {
    my $export = [];
    foreach my $table (@{$self->tables}) {
        if ($self->data->{$table}) {
            push(@{$export}, [ $table, $self->data->{$table} ]);
        }
    }
    return encode_json($export);
}

# Generic export method for basic tables
method _export_general (Str $table) {
    my $result = $self->c->model("DB::$table")->search;
    my @col_names = $result->result_source->columns;
    my $rows = [];
    while (my $row = $result->next) {
        my $columns = {};
        foreach my $name (@col_names) {
            $columns->{$name} = $row->get_column($name);
        }
        push(@{$rows}, $columns);
    }
    $self->{data}->{$table} = $rows;
}

# Generic import method for basic tables
method _import_general (ArrayRef $table) {
    my $name = $table->[0];
    my $data = $table->[1];
    foreach my $row (@{$data}) {
        $self->c->model("DB::$name")->update_or_create(%{$row});
    }
}

# Drop the existing table and replace it with new data. This is probably a
# lot slower than something like mysqldump. Care should be taken when
# using on large tables.
method _import_replace (ArrayRef $table) {
    my $name = $table->[0];
    my $old_data = $self->c->model("DB::$name")->search;
    $old_data->delete_all;
    $self->_import_general($table);
}

1;
