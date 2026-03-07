package # hide from PAUSE
    DBIO::Test::Schema::ArtistSubclass;

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';

__PACKAGE__->table(__PACKAGE__->table);

1;