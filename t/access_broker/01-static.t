# ABSTRACT: AccessBroker test
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('DBIO::AccessBroker');

# Verify it's a class with the right interface
can_ok('DBIO::AccessBroker', qw(
  connect_info_for
  connect_info_for_storage
  has_read_write_routing
  has_rotating_credentials
  is_transaction_safe
  needs_refresh
  refresh
  current_connect_info_for
  current_connect_info_for_storage
));

# Static broker tests
use_ok('DBIO::AccessBroker::Static');

# Construct with driver-native params
my $broker = DBIO::AccessBroker::Static->new(
  host     => 'localhost',
  dbname   => 'mydb',
  username => 'user',
  password => 'pass',
);
ok $broker, 'Static broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# connect_info_for returns same info for read and write
my $write_info = $broker->connect_info_for('write');
my $read_info  = $broker->connect_info_for('read');
is_deeply $write_info, $read_info, 'read and write return same info';
is $write_info->{host}, 'localhost', 'host correct';
is $write_info->{dbname}, 'mydb', 'dbname correct';
is $write_info->{user}, 'user', 'user correct';
is $write_info->{password}, 'pass', 'password correct';

# needs_refresh is always false
ok !$broker->needs_refresh, 'static never needs refresh';
ok !$broker->has_read_write_routing, 'static broker has no read/write routing';
ok !$broker->has_rotating_credentials, 'static broker has no rotating credentials';
ok $broker->is_transaction_safe, 'static broker is transaction safe';

# current_connect_info_for is convenience (checks refresh + returns info)
my $current = $broker->current_connect_info_for('write');
is_deeply $current, $write_info, 'current_connect_info_for same as connect_info_for';

# Test driver-native hashref format
subtest 'connect_info_for returns driver-native hashref' => sub {
  my $broker = DBIO::AccessBroker::Static->new(
    host => '127.0.0.1',
    port => 5432,
    dbname => 'mydb',
    username => 'user',
    password => 'pass',
  );

  my $info = $broker->connect_info_for('write');
  ok(ref $info eq 'HASH', 'returns hashref');
  is($info->{host}, '127.0.0.1', 'host key present');
  is($info->{port}, 5432, 'port key present');
  is($info->{dbname}, 'mydb', 'dbname key present');
  is($info->{user}, 'user', 'user key present');
  is($info->{password}, 'pass', 'password key present');
};

done_testing;
