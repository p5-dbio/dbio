# ABSTRACT: AccessBroker transaction safety guard test
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warn;

use DBIO::Test::Schema;
use DBIO::AccessBroker::Static;

{
  package UnsafeStaticBroker;
  use base 'DBIO::AccessBroker::Static';

  sub has_read_write_routing { 1 }
}

my $unsafe = UnsafeStaticBroker->new(
  dsn      => 'dbi:SQLite:dbname=:memory:',
  username => '',
  password => '',
);

my $schema = DBIO::Test::Schema->connect($unsafe);

throws_ok(
  sub { $schema->txn_begin },
  qr/unsafe AccessBroker .* transaction/i,
  'transactions are refused for unsafe brokers by default',
);

{
  local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
  warnings_like(
    sub {
      my $guard = $schema->txn_scope_guard;
      $guard->rollback;
    },
    qr/unsafe AccessBroker .* override/i,
    'unsafe broker override emits a warning',
  );
}

done_testing;
