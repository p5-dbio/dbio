use warnings;
use strict;

use Test::More;

use lib qw(t/lib);
use DBICTest; # do not remove even though it is not used (pulls in MRO::Compat if needed)

{
  package AAA;

  use base "DBIO::Core";
}

{
  package BBB;

  use base 'AAA';

  #Injecting a direct parent.
  __PACKAGE__->inject_base( __PACKAGE__, 'AAA' );
}

{
  package CCC;

  use base 'AAA';

  #Injecting an indirect parent.
  __PACKAGE__->inject_base( __PACKAGE__, 'DBIO::Core' );
}

eval { mro::get_linear_isa('BBB'); };
ok (! $@, "Correctly skipped injecting a direct parent of class BBB");

eval { mro::get_linear_isa('CCC'); };
ok (! $@, "Correctly skipped injecting an indirect parent of class BBB");

use DBIO::MSSQL::Storage::Sybase;

is_deeply (
  mro::get_linear_isa('DBIO::MSSQL::Storage::Sybase'),
  [qw/
    DBIO::MSSQL::Storage::Sybase
    DBIO::Sybase::Storage
    DBIO::MSSQL::Storage
    DBIO::Storage::DBI::UniqueIdentifier
    DBIO::Storage::DBI::IdentityInsert
    DBIO::Storage::DBI
    DBIO::Storage::DBIHacks
    DBIO::Storage
    DBIO
    DBIO::Componentised
    Class::C3::Componentised
    DBIO::AccessorGroup
    Class::Accessor::Grouped
  /],
  'Correctly ordered ISA of DBIO::MSSQL::Storage::Sybase'
);

my $storage = DBIO::MSSQL::Storage::Sybase->new;
$storage->connect_info(['dbi:SQLite::memory:']); # determine_driver's init() connects for this subclass
$storage->_determine_driver;
is (
  $storage->can('sql_limit_dialect'),
  'DBIO::MSSQL::Storage'->can('sql_limit_dialect'),
  'Correct method picked'
);

if ($] >= 5.010) {
  ok (! $INC{'Class/C3.pm'}, 'No Class::C3 loaded on perl 5.10+');

  # Class::C3::Componentised loads MRO::Compat unconditionally to satisfy
  # the assumption that once Class::C3::X is loaded, so is Class::C3
  #ok (! $INC{'MRO/Compat.pm'}, 'No MRO::Compat loaded on perl 5.10+');
}

done_testing;
