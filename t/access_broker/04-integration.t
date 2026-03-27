# ABSTRACT: AccessBroker schema connect test
use strict;
use warnings;

use Test::More;

use DBIO::Test::Schema;
use DBIO::AccessBroker::Static;

my $broker = DBIO::AccessBroker::Static->new(
  dsn      => 'dbi:SQLite:dbname=:memory:',
  username => '',
  password => '',
);

my $schema = DBIO::Test::Schema->connect($broker);

ok $schema, 'schema created with broker';
isa_ok $schema->storage, 'DBIO::Storage::DBI';
is $schema->storage->access_broker, $broker, 'storage keeps broker';
is $schema->storage->access_broker_mode, 'write', 'default broker mode is write';
is $broker->_storage, $schema->storage, 'broker is attached to storage';

is_deeply(
  $schema->storage->_dbi_connect_info,
  [
    'dbi:SQLite:dbname=:memory:',
    '',
    '',
    {
      AutoCommit         => 1,
      PrintError         => 0,
      RaiseError         => 1,
      ShowErrorStatement => 1,
    },
  ],
  'initial DBI connect info is derived from the broker',
);

done_testing;
