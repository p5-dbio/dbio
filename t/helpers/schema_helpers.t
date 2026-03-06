use strict;
use warnings;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use DBIOTest;

my $schema = DBIOTest->init_schema();

# --- source() "did you mean?" suggestions ---
{
  # Exact match still works
  my $src = $schema->source('CD');
  isa_ok($src, 'DBIO::ResultSource', 'source() exact match works');

  # Typo close to Artist (1 char missing)
  throws_ok {
    $schema->source('Artis')
  } qr/Did you mean:.*Artist/, 'source() suggests Artist for "Artis"';

  # Typo close to CD (1 char added)
  throws_ok {
    $schema->source('Cdd')
  } qr/Did you mean:.*CD/, 'source() suggests CD for "Cdd"';

  # Case-insensitive distance calculation
  throws_ok {
    $schema->source('artist')
  } qr/Did you mean:.*Artist/i, 'source() case-insensitive suggestion';

  # Completely wrong name — should show available sources, not suggestions
  throws_ok {
    $schema->source('ZZZZZZ')
  } qr/Available sources:/, 'source() shows available sources for no match';

  # Completely wrong name should NOT show "Did you mean"
  throws_ok {
    $schema->source('ZZZZZZ')
  } qr/Can't find source for ZZZZZZ/,
    'source() error message includes the bad name';

  # No argument
  throws_ok {
    $schema->source()
  } qr/expects a source name/, 'source() with no args throws';

  # Full class name mapping still works
  my $mapped = eval { $schema->source('DBIOTest::Schema::CD') };
  ok($mapped, 'source() accepts full class name');
}

done_testing;
