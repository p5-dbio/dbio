package DBIO::Test::ResultSetManager::Foo;
# ABSTRACT: Test result class for ResultSetManager component testing

use warnings;
use strict;

use base 'DBIO::Core';

__PACKAGE__->load_components(qw/ ResultSetManager /);
__PACKAGE__->table('foo');

sub bar : ResultSet { 'good' }

1;
