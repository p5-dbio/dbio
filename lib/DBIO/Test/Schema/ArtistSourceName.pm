package DBIO::Test::Schema::ArtistSourceName;
# ABSTRACT: Test result class for custom source name on the artist table

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';
__PACKAGE__->table(__PACKAGE__->table);
__PACKAGE__->source_name('SourceNameArtists');

1;
