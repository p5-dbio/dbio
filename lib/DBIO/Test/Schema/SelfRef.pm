package DBIO::Test::Schema::SelfRef;
# ABSTRACT: Test result class for the self_ref table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('self_ref');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many( aliases => 'DBIO::Test::Schema::SelfRefAlias' => 'self_ref' );

1;
