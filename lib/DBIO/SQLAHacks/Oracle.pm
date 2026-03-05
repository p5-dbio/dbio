package # Hide from PAUSE
  DBIO::SQLAHacks::Oracle;

use warnings;
use strict;

use base qw( DBIO::SQLMaker::Oracle );

1;
