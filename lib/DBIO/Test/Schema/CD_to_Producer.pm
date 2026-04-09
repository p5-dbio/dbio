package DBIO::Test::Schema::CD_to_Producer;
# ABSTRACT: Test result class for the cd_to_producer table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('cd_to_producer');
__PACKAGE__->add_columns(
  cd => { data_type => 'integer' },
  producer => { data_type => 'integer' },
  attribute => { data_type => 'integer', is_nullable => 1 },
);
__PACKAGE__->set_primary_key(qw/cd producer/);

# the undef condition in this rel is *deliberate*
# tests oddball legacy syntax
__PACKAGE__->belongs_to(
  'cd', 'DBIO::Test::Schema::CD'
);

__PACKAGE__->belongs_to(
  'producer', 'DBIO::Test::Schema::Producer',
  { 'foreign.producerid' => 'self.producer' },
  { on_delete => undef, on_update => undef },
);

1;
