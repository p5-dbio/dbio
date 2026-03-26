# ABSTRACT: AccessBroker test
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('DBIO::AccessBroker');

# Verify it's a class with the right interface
can_ok('DBIO::AccessBroker', qw(
  connect_info_for
  needs_refresh
  refresh
  current_connect_info_for
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

# current_connect_info_for is convenience (checks refresh + returns info)
my $current = $broker->current_connect_info_for('write');
is_deeply $current, $write_info, 'current_connect_info_for same as connect_info_for';

done_testing;