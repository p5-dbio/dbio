package # hide from PAUSE
    DBIO::Test::Schema::Owners;
# ABSTRACT: Test result class for the owners table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('owners');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => '100',
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_unique_constraint(['name']);

__PACKAGE__->has_many(books => "DBIO::Test::Schema::BooksInLibrary", "owner");

1;
