package # hide from PAUSE
    DBIO::Test::Taint::Classes::Auto;
# ABSTRACT: Test class for taint mode with auto-loading

use warnings;
use strict;

use base 'DBIO::Core';
__PACKAGE__->table('test');

1;
