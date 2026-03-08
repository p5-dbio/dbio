use strict;
use warnings;

use Test::More;

plan skip_all => 'Test requires a real database connection (use DBIO::SQLite test suite)';

use Test::Exception;

use lib qw(t/lib);
use DBICTest;

my $schema = DBICTest->init_schema();

my $cd = $schema->resultset('CD')->search ({}, { columns => ['year'], rows => 1 })->single;


throws_ok (
  sub { $cd->tracks },
  qr/Unable to resolve relationship .+ column .+ not loaded from storage/,
  'Correct exception on nonresolvable object-based condition'
);

done_testing;
