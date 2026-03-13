package DBIO::Test::Namespace::RtBug41083::ResultSet_A::A;
# ABSTRACT: Test fixture for namespace resolution
use strict;
use warnings;
use base 'DBIO::Test::Namespace::RtBug41083::ResultSet';

sub fooBar { 1; }
1;
