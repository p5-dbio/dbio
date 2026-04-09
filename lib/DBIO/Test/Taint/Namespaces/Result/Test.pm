package DBIO::Test::Taint::Namespaces::Result::Test;
# ABSTRACT: Test result class for taint mode namespace loading

use warnings;
use strict;

use base 'DBIO::Core';
__PACKAGE__->table('test');

1;
