package # hide from PAUSE
    DBIO::Test::ResultSetManager;

use warnings;
use strict;

use base 'DBIO::Schema';

__PACKAGE__->load_classes("Foo");

1;
