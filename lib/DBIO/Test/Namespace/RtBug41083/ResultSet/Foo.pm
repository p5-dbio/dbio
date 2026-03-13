package DBIO::Test::Namespace::RtBug41083::ResultSet::Foo;
# ABSTRACT: Test fixture for namespace resolution
use strict;
use warnings;
use base 'DBIO::Test::Namespace::RtBug41083::ResultSet';

sub fooBar { 1; }

1;
