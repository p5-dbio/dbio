# ABSTRACT: ReadWrite broker test
use strict;
use warnings;
use Test::More;

use_ok('DBIO::AccessBroker::ReadWrite');

# Setup: primary + two replicas
my $broker = DBIO::AccessBroker::ReadWrite->new(
  write => {
    dsn => 'dbi:Pg:host=primary', username => 'writer', password => 'pw',
  },
  read => [
    { dsn => 'dbi:Pg:host=replica1', username => 'reader1', password => 'pw' },
    { dsn => 'dbi:Pg:host=replica2', username => 'reader2', password => 'pw' },
  ],
);

ok $broker, 'ReadWrite broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# Write always returns primary info
my $write1 = $broker->connect_info_for('write');
my $write2 = $broker->connect_info_for('write');
is $write1->[0], 'dbi:Pg:host=primary', 'write DSN is primary';
is $write1->[1], 'writer', 'write username';
is_deeply $write1, $write2, 'write info is stable';

# Read round-robins through replicas
my $read1 = $broker->connect_info_for('read');
my $read2 = $broker->connect_info_for('read');
is $read1->[0], 'dbi:Pg:host=replica1', 'first read is replica1';
is $read2->[0], 'dbi:Pg:host=replica2', 'second read is replica2';

# Third call cycles back to first replica
my $read3 = $broker->connect_info_for('read');
is $read3->[0], 'dbi:Pg:host=replica1', 'round-robin cycles back';

# Write and read are different
isnt $write1->[0], $read1->[0], 'write and read are different DSNs';
ok $broker->has_read_write_routing, 'read/write broker declares routing';
ok !$broker->has_rotating_credentials, 'read/write broker has no rotating credentials';
ok !$broker->is_transaction_safe, 'read/write broker is not transaction safe by default';

done_testing;
