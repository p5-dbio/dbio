use strict;
use warnings;
use Test::More;
use Test::Exception;
use Test::Warn;

use lib qw(t/lib);
use DBIO::Test;

lives_ok (sub {
  warnings_exist ( sub {
      package DBICNSTestOther;
      use base qw/DBIO::Schema/;
      __PACKAGE__->load_namespaces(
          result_namespace => [ '+DBICNSTest::Rslt', '+DBICNSTest::OtherRslt' ],
          resultset_namespace => '+DBICNSTest::RSet',
      );
    },
    qr/load_namespaces found ResultSet class 'DBICNSTest::RSet::C' with no corresponding Result class/,
  );
});

my $source_a = DBICNSTestOther->source('A');
isa_ok($source_a, 'DBIO::ResultSource::Table');
my $rset_a   = DBICNSTestOther->resultset('A');
isa_ok($rset_a, 'DBICNSTest::RSet::A');

my $source_b = DBICNSTestOther->source('B');
isa_ok($source_b, 'DBIO::ResultSource::Table');
my $rset_b   = DBICNSTestOther->resultset('B');
isa_ok($rset_b, 'DBIO::ResultSet');

my $source_d = DBICNSTestOther->source('D');
isa_ok($source_d, 'DBIO::ResultSource::Table');

done_testing;
