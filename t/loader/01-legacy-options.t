use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Loader::Base;

throws_ok {
  DBIO::Loader::Base->new(use_moose => 1);
} qr/\Quse_moose is no longer supported\E/,
  'use_moose is rejected early';

throws_ok {
  DBIO::Loader::Base->new(result_roles => ['MyApp::Role']);
} qr/\Qresult_roles is no longer supported\E/,
  'result_roles is rejected early';

throws_ok {
  DBIO::Loader::Base->new(result_roles_map => { Artist => ['MyApp::Role'] });
} qr/\Qresult_roles_map is no longer supported\E/,
  'result_roles_map is rejected early';

done_testing;
