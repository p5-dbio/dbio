use strict;
use warnings;
use Test::More;
use Class::Inspector ();

use lib 't/lib';

use DBIO::Test;

is(DBIO::Test::Schema->source('Artist')->resultset_class, 'DBIO::Test::BaseResultSet', 'default resultset class');
ok(!Class::Inspector->loaded('DBICNSTest::ResultSet::A'), 'custom resultset class not loaded');

DBIO::Test::Schema->source('Artist')->resultset_class('DBICNSTest::ResultSet::A');

ok(!Class::Inspector->loaded('DBICNSTest::ResultSet::A'), 'custom resultset class not loaded on SET');
is(DBIO::Test::Schema->source('Artist')->resultset_class, 'DBICNSTest::ResultSet::A', 'custom resultset class set');
ok(Class::Inspector->loaded('DBICNSTest::ResultSet::A'), 'custom resultset class loaded on GET');

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $resultset = $schema->resultset('Artist')->search;
isa_ok($resultset, 'DBICNSTest::ResultSet::A', 'resultset is custom class');

done_testing;
