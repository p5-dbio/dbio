package # hide from PAUSE
    DBIO::Test::Schema::LinerNotes;
# ABSTRACT: Test result class for the liner_notes table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('liner_notes');
__PACKAGE__->add_columns(
  'liner_id' => {
    data_type => 'integer',
  },
  'notes' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('liner_id');
__PACKAGE__->belongs_to(
  'cd', 'DBIO::Test::Schema::CD', 'liner_id'
);

1;
