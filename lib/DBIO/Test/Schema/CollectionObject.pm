package # hide from PAUSE
    DBIO::Test::Schema::CollectionObject;

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('collection_object');
__PACKAGE__->add_columns(
  'collection' => {
    data_type => 'integer',
  },
  'object' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key(qw/collection object/);

__PACKAGE__->belongs_to( collection => "DBIO::Test::Schema::Collection",
                         { "foreign.collectionid" => "self.collection" }
                       );
__PACKAGE__->belongs_to( object => "DBIO::Test::Schema::TypedObject",
                         { "foreign.objectid" => "self.object" }
                       );

1;
