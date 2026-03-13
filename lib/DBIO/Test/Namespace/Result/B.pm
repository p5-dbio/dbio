package DBIO::Test::Namespace::Result::B;
# ABSTRACT: Test fixture for namespace resolution

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('b');
__PACKAGE__->add_columns('b');
1;
