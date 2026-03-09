use warnings;
use strict;

use Test::More;
use File::Temp ();
use DBIO::Test;

plan skip_all => 'DBIO::SQLite::Storage not available (moved to DBIO-SQLite distribution)'
  unless eval { require DBIO::SQLite::Storage; 1 };

# Once upon a time there was a problem with a leaking $sth
# which in turn delayed the $dbh destruction, which in turn
# made the inode comaprison fire at the wrong time
# This simulates the problem without doing much else
for (1..2) {
  my $tmp = File::Temp->new( SUFFIX => '.sqlite', UNLINK => 1 );
  my $schema = DBIO::Test->init_schema(
    dsn       => 'dbi:SQLite:' . $tmp->filename,
    user      => '',
    pass      => '',
    no_deploy => 1,
  );
  $schema->storage->ensure_connected;
  isa_ok ($schema, 'DBIO::Test::Schema');
}

done_testing;
