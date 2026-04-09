package DBIO::Test::Schema::NoPrimaryKey;
# ABSTRACT: Test result class for a table with no primary key

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('noprimarykey');
__PACKAGE__->add_columns(
  'foo' => { data_type => 'integer' },
  'bar' => { data_type => 'integer' },
  'baz' => { data_type => 'integer' },
);

__PACKAGE__->add_unique_constraint(foo_bar => [ qw/foo bar/ ]);

1;
