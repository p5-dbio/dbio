package DBIO::Admin::Descriptive;

use warnings;
use strict;

use base 'Getopt::Long::Descriptive';

require DBIO::Admin::Usage;
sub usage_class { 'DBIO::Admin::Usage'; }

1;
