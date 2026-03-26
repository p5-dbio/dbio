# ABSTRACT: ReadWrite broker test
use strict;
use warnings;
use Test::More;
use DBI;

use_ok('DBIO::AccessBroker::ReadWrite');

# Setup: two SQLite in-memory DBs (simulating primary + replica)
my $broker = DBIO::AccessBroker::ReadWrite->new(
  write => {
    dsn => 'dbi:SQLite:dbname=:memory:',
    username => '', password => '',
  },
  read => [
    { dsn => 'dbi:SQLite:dbname=:memory:', username => '', password => '' },
    { dsn => 'dbi:SQLite:dbname=:memory:', username => '', password => '' },
  ],
);

ok $broker, 'ReadWrite broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# Write always returns the same handle
my $write1 = $broker->dbh_for('write');
my $write2 = $broker->dbh_for('write');
is $write1, $write2, 'write handle is stable';

# Read returns handles (round-robin)
my $read1 = $broker->dbh_for('read');
my $read2 = $broker->dbh_for('read');
ok $read1, 'got read handle 1';
ok $read2, 'got read handle 2';

# Round-robin cycles back to first replica
my $read3 = $broker->dbh_for('read');
is $read3, $read1, 'round-robin cycles back to first replica';

# Write and read are different handles
isnt $write1, $read1, 'write and read are different handles';

$broker->disconnect;
done_testing;