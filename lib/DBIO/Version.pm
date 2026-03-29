package DBIO::Version;
# ABSTRACT: Schema class for versioning support
use base 'DBIO::Schema';
use strict;
use warnings;

use DBIO::Version::Table;

__PACKAGE__->register_class('Table', 'DBIO::Version::Table');

1;
