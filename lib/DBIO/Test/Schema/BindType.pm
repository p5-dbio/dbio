package # hide from PAUSE
    DBIO::Test::Schema::BindType;
# ABSTRACT: Test result class for the bindtype_test table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('bindtype_test');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'bytea' => {
    data_type => 'bytea',
    is_nullable => 1,
  },
  'blob' => {
    data_type => 'blob',
    is_nullable => 1,
  },
  'clob' => {
    data_type => 'clob',
    is_nullable => 1,
  },
  'a_memo' => {
    data_type => 'mediumtext',
    is_nullable => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;
