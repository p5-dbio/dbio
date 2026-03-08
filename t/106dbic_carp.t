use strict;
use warnings;

# without this the stacktrace of $schema will be activated
BEGIN { $ENV{DBIO_TRACE} = 0 }

use Test::More;
use Test::Warn;
use Test::Exception;
use DBIO::Test;
use DBIO::Carp;

{
  sub DBIOTest::DBIOCarp::frobnicate {
    DBIOTest::DBIOCarp::branch1();
    DBIOTest::DBIOCarp::branch2();
  }

  sub DBIOTest::DBIOCarp::branch1 { carp_once 'carp1' }
  sub DBIOTest::DBIOCarp::branch2 { carp_once 'carp2' }


  warnings_exist {
    DBIOTest::DBIOCarp::frobnicate();
  } [
    qr/carp1/,
    qr/carp2/,
  ], 'expected warnings from carp_once';
}

{
  {
    package DBIOTest::DBIOCarp::Exempt;
    use DBIO::Carp;

    sub _skip_namespace_frames { qr/^DBIOTest::DBIOCarp::Exempt/ }

    sub thrower {
      sub {
        DBIO::Test->init_schema(no_deploy => 1)->storage->dbh_do(sub {
          shift->throw_exception('time to die');
        })
      }->();
    }

    sub dcaller {
      sub {
        thrower();
      }->();
    }

    sub warner {
      eval {
        sub {
          eval {
            carp ('time to warn')
          }
        }->()
      }
    }

    sub wcaller {
      warner();
    }
  }

  # the __LINE__ relationship below is important - do not reformat
  throws_ok { DBIOTest::DBIOCarp::Exempt::dcaller() }
    qr/\QDBIOTest::DBIOCarp::Exempt::thrower(): time to die at @{[ __FILE__ ]} line @{[ __LINE__ - 1 ]}\E$/,
    'Expected exception callsite and originator'
  ;

  # the __LINE__ relationship below is important - do not reformat
  warnings_like { DBIOTest::DBIOCarp::Exempt::wcaller() }
    qr/\QDBIOTest::DBIOCarp::Exempt::warner(): time to warn at @{[ __FILE__ ]} line @{[ __LINE__ - 1 ]}\E$/,
  ;
}

done_testing;
