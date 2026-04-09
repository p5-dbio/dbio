package DBIO::Test::Schema::SelfRefAlias;
# ABSTRACT: Test result class for the self_ref_alias table

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('self_ref_alias');
__PACKAGE__->add_columns(
  'self_ref' => {
    data_type => 'integer',
  },
  'alias' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key(qw/self_ref alias/);

__PACKAGE__->belongs_to( self_ref => 'DBIO::Test::Schema::SelfRef' );
__PACKAGE__->belongs_to( alias => 'DBIO::Test::Schema::SelfRef' );

1;
