package # hide from PAUSE
    DBIO::ClassResolver::PassThrough;

use strict;
use warnings;

sub class {
  shift;
  return shift;
}

1;
