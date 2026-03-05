use strict;
use warnings;

use Test::More;

use lib 't/lib';
use DBICTest;

BEGIN {
    require DBIO;
    plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('admin')
      unless DBIO::Optional::Dependencies->req_ok_for('admin');
}

use_ok 'DBIO::Admin';


done_testing;
