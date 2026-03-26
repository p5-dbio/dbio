# ABSTRACT: AccessBroker test
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('DBIO::AccessBroker');

# Verify it's a class with the right interface
can_ok('DBIO::AccessBroker', qw(
  dbh_for
  needs_refresh
  refresh
  connect_info_for
));

# Static broker tests
use_ok('DBIO::AccessBroker::Static');

# Construct with DSN
my $broker = DBIO::AccessBroker::Static->new(
  dsn      => 'dbi:SQLite:dbname=:memory:',
  username => '',
  password => '',
);
ok $broker, 'Static broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# connect_info_for returns same info for read and write
my $write_info = $broker->connect_info_for('write');
my $read_info  = $broker->connect_info_for('read');
is_deeply $write_info, $read_info, 'read and write return same info';
is $write_info->[0], 'dbi:SQLite:dbname=:memory:', 'DSN correct';

# needs_refresh is always false
ok !$broker->needs_refresh, 'static never needs refresh';

# dbh_for returns a live handle
my $dbh = $broker->dbh_for('write');
ok $dbh, 'got a dbh';
ok $dbh->ping, 'dbh is alive';

# Same handle for read and write
my $dbh2 = $broker->dbh_for('read');
is $dbh2, $dbh, 'read and write share the same handle';

# Cleanup
$broker->disconnect;

done_testing;