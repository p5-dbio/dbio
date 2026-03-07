package DBIO::SQLMaker::SQLite;

use warnings;
use strict;

use base qw( DBIO::SQLMaker );

#
# SQLite does not understand SELECT ... FOR UPDATE
# Disable it here
sub _lock_select () { '' };

1;
