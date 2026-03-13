package # hide from PAUSE
    DBIO::Test::Schema::BooksInLibrary;
# ABSTRACT: Test result class for the books table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('books');
__PACKAGE__->add_columns(
  'id' => {
    # part of a test (auto-retrieval of PK regardless of autoinc status)
    # DO NOT define
    #is_auto_increment => 1,

    data_type => 'integer',
  },
  'source' => {
    data_type => 'varchar',
    size      => '100',
  },
  'owner' => {
    data_type => 'integer',
  },
  'title' => {
    data_type => 'varchar',
    size      => '100',
  },
  'price' => {
    data_type => 'integer',
    is_nullable => 1,
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint (['title']);

__PACKAGE__->resultset_attributes({where => { source => "Library" } });

__PACKAGE__->belongs_to ( owner => 'DBIO::Test::Schema::Owners', 'owner' );

1;
