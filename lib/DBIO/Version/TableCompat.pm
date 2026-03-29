package DBIO::Version::TableCompat;
# ABSTRACT: Result class for the legacy SchemaVersions compatibility table
use base 'DBIO::Core';
use strict;
use warnings;

__PACKAGE__->table('SchemaVersions');

__PACKAGE__->add_columns(
  Version   => { data_type => 'VARCHAR' },
  Installed => { data_type => 'VARCHAR' },
);

__PACKAGE__->set_primary_key('Version');

1;
