package DBIO::Test::Schema::ArtistSubclass;
# ABSTRACT: Test result subclass of the artist table

use warnings;
use strict;

use base 'DBIO::Test::Schema::Artist';

__PACKAGE__->table(__PACKAGE__->table);

1;