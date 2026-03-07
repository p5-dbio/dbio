package # hide from PAUSE
    DBIO::Test::Schema::TimestampPrimaryKey;

use warnings;
use strict;

use base qw/DBIO::Test::BaseResult/;

__PACKAGE__->table('timestamp_primary_key_test');

__PACKAGE__->add_columns(
  'id' => {
    data_type => 'timestamp',
    default_value => \'current_timestamp',
    retrieve_on_insert => 1,
  },
);

__PACKAGE__->set_primary_key('id');

1;
