use strict;
use warnings;

use Test::Exception tests => 1;
use lib qw(t/lib);
use DBICTest;
use DBICTest::Schema;
use DBIO::ResultSource::Table;

my $schema = DBICTest->init_schema();

my $foo = DBIO::ResultSource::Table->new({ name => "foo" });
my $bar = DBIO::ResultSource::Table->new({ name => "bar" });

lives_ok {
    $schema->register_source(foo => $foo);
    $schema->register_source(bar => $bar);
} 'multiple classless sources can be registered';
