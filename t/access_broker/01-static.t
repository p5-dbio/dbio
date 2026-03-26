# ABSTRACT: AccessBroker test
use strict;
use warnings;
use Test::More;
use Test::Exception;

use_ok('DBIO::AccessBroker');

# Verify it's a class with the right interface
can_ok('DBIO::AccessBroker', qw(
  dbh_for
  needs_refresh
  refresh
  connect_info_for
));

done_testing;