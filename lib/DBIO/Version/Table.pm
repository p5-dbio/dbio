package DBIO::Version::Table;
# ABSTRACT: Result class for the schema versions table
use base 'DBIO::Core';
use strict;
use warnings;

__PACKAGE__->table('dbio_schema_versions');

__PACKAGE__->add_columns(
  version => {
    data_type   => 'VARCHAR',
    is_nullable => 0,
    size        => 10,
  },
  installed => {
    data_type   => 'VARCHAR',
    is_nullable => 0,
    size        => 20,
  },
);

__PACKAGE__->set_primary_key('version');

1;
