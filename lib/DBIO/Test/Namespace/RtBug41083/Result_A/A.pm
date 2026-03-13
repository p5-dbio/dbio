package DBIO::Test::Namespace::RtBug41083::Result_A::A;
# ABSTRACT: Test fixture for namespace resolution
use strict;
use warnings;
use base 'DBIO::Core';
__PACKAGE__->table('a');
__PACKAGE__->add_columns('a');
1;
