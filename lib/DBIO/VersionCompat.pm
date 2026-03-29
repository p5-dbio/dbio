package DBIO::VersionCompat;
# ABSTRACT: Schema class for legacy SchemaVersions compatibility
use base 'DBIO::Schema';
use strict;
use warnings;

use DBIO::Version::TableCompat;

__PACKAGE__->register_class('TableCompat', 'DBIO::Version::TableCompat');

1;
