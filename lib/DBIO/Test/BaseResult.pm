package DBIO::Test::BaseResult;
# ABSTRACT: Base class for DBIO test Result classes

use strict;
use warnings;

use base 'DBIO::Core';

__PACKAGE__->table('bogus');
__PACKAGE__->resultset_class('DBIO::Test::BaseResultSet');

1;
