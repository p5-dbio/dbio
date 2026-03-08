use strict;
use warnings;

use Test::More;
plan skip_all => 'Test requires a real database connection (use DBIO::SQLite test suite)';

use lib qw(t/lib);

my $schema = DBICTest->init_schema();

eval {
  my $cd = $schema->resultset('CD')->first;
  my $track = $schema->resultset('Track')->new_result({
    cd => $cd,
    title => 'Multicreate rocks',
    cd_single => {
      artist => $cd->artist,
      year => 2008,
      title => 'Disemboweling MultiCreate',
    },
  });

  isa_ok ($track, 'DBICTest::Track', 'Main Track object created');

  $track->insert;

  ok(1, 'created track');

  is($track->title, 'Multicreate rocks', 'Correct Track title');

  my $single = $track->cd_single;

  ok($single->cdid, 'Got cdid');
};

done_testing;
