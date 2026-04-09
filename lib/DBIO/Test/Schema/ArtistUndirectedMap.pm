package DBIO::Test::Schema::ArtistUndirectedMap;
# ABSTRACT: Test result class for the artist_undirected_map table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('artist_undirected_map');
__PACKAGE__->add_columns(
  'id1' => { data_type => 'integer' },
  'id2' => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key(qw/id1 id2/);

__PACKAGE__->belongs_to( 'artist1', 'DBIO::Test::Schema::Artist', 'id1', { on_delete => 'RESTRICT', on_update => 'CASCADE'} );
__PACKAGE__->belongs_to( 'artist2', 'DBIO::Test::Schema::Artist', 'id2', { on_delete => undef, on_update => undef} );
__PACKAGE__->has_many(
  'mapped_artists', 'DBIO::Test::Schema::Artist',
  [ {'foreign.artistid' => 'self.id1'}, {'foreign.artistid' => 'self.id2'} ],
  { cascade_delete => 0 },
);

1;
