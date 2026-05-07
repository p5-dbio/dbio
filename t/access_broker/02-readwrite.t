# ABSTRACT: ReadWrite broker test
use strict;
use warnings;
use Test::More;

use_ok('DBIO::AccessBroker::ReadWrite');

# Setup: primary + two replicas
my $broker = DBIO::AccessBroker::ReadWrite->new(
  write => {
    host => 'primary', dbname => 'mydb', user => 'writer', password => 'pw',
  },
  read => [
    { host => 'replica1', dbname => 'mydb', user => 'reader1', password => 'pw' },
    { host => 'replica2', dbname => 'mydb', user => 'reader2', password => 'pw' },
  ],
);

ok $broker, 'ReadWrite broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# Write always returns primary info
my $write1 = $broker->connect_info_for('write');
my $write2 = $broker->connect_info_for('write');
is $write1->{host}, 'primary', 'write host is primary';
is $write1->{user}, 'writer', 'write user';
is_deeply $write1, $write2, 'write info is stable';

# Read round-robins through replicas
my $read1 = $broker->connect_info_for('read');
my $read2 = $broker->connect_info_for('read');
is $read1->{host}, 'replica1', 'first read is replica1';
is $read2->{host}, 'replica2', 'second read is replica2';

# Third call cycles back to first replica
my $read3 = $broker->connect_info_for('read');
is $read3->{host}, 'replica1', 'round-robin cycles back';

# Write and read are different
isnt $write1->{host}, $read1->{host}, 'write and read are different hosts';
ok $broker->has_read_write_routing, 'read/write broker declares routing';
ok !$broker->has_rotating_credentials, 'read/write broker has no rotating credentials';
ok !$broker->is_transaction_safe, 'read/write broker is not transaction safe by default';

subtest 'connect_info_for returns driver-native hashref' => sub {
  my $broker = DBIO::AccessBroker::ReadWrite->new(
    write => { host => 'w-host', dbname => 'mydb', user => 'u', password => 'p' },
    read  => [
      { host => 'r1-host', dbname => 'mydb', user => 'u', password => 'p' },
      { host => 'r2-host', dbname => 'mydb', user => 'u', password => 'p' },
    ],
  );

  my $write_info = $broker->connect_info_for('write');
  ok(ref $write_info eq 'HASH', 'write returns hashref');
  is($write_info->{host}, 'w-host', 'write host key present');

  my $read_info = $broker->connect_info_for('read');
  ok(ref $read_info eq 'HASH', 'read returns hashref');
  is($read_info->{host}, 'r1-host', 'first read host key present');
};

done_testing;
