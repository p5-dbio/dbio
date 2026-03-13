package DBIO::Test::Namespace::Result::A;
# ABSTRACT: Test fixture for namespace resolution

use warnings;
use strict;

use base qw/DBIO::Core/;
__PACKAGE__->table('a');
__PACKAGE__->add_columns('a');
1;
