package DBIO::Test::Taint::Classes::Manual;
# ABSTRACT: Test class for taint mode with manual loading

use warnings;
use strict;

use base 'DBIO::Core';
__PACKAGE__->table('test');

1;
