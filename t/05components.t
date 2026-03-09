use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::ForeignComponent;

#   Tests if foreign component was loaded by calling foreign's method
ok( DBIO::Test::ForeignComponent->foreign_test_method, 'foreign component' );

#   Test for inject_base to filter out duplicates
{   package DBIOTest::_InjectBaseTest;
    use base qw/ DBIO /;
    package DBIOTest::_InjectBaseTest::A;
    package DBIOTest::_InjectBaseTest::B;
    package DBIOTest::_InjectBaseTest::C;
}
DBIOTest::_InjectBaseTest->inject_base( 'DBIOTest::_InjectBaseTest', qw/
    DBIOTest::_InjectBaseTest::A
    DBIOTest::_InjectBaseTest::B
    DBIOTest::_InjectBaseTest::B
    DBIOTest::_InjectBaseTest::C
/);
is_deeply( \@DBIOTest::_InjectBaseTest::ISA,
    [qw/
        DBIOTest::_InjectBaseTest::A
        DBIOTest::_InjectBaseTest::B
        DBIOTest::_InjectBaseTest::C
        DBIO
    /],
    'inject_base filters duplicates'
);

use_ok('DBIO::AccessorGroup');
use_ok('DBIO::Componentised');

done_testing;
