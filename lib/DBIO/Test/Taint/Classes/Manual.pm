package # hide from PAUSE
    DBIO::Test::Taint::Classes::Manual;

use warnings;
use strict;

use base 'DBIO::Core';
__PACKAGE__->table('test');

1;
