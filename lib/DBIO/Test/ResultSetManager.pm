package DBIO::Test::ResultSetManager;
# ABSTRACT: Test schema for ResultSetManager component testing

use warnings;
use strict;

use base 'DBIO::Schema';

__PACKAGE__->load_classes("Foo");

1;
