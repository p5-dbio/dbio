package # hide from PAUSE
    DBIO::Test::Schema::ArtistSourceName;

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';
__PACKAGE__->table(__PACKAGE__->table);
__PACKAGE__->source_name('SourceNameArtists');

1;
