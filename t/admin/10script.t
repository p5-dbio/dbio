# vim: filetype=perl
use strict;
use warnings;

BEGIN {
  # just in case the user env has stuff in it
  delete $ENV{DBICTEST_VERSION_WARNS_INDISCRIMINATELY};
}

use Test::More;
use Config;
use File::Spec;
use JSON::MaybeXS;
use lib qw(t/lib);
use DBICTest;

$ENV{PATH} = '';
$ENV{PERL5LIB} = join ($Config{path_sep}, @INC);

# test the script is setting @INC properly
test_exec (qw|-It/lib/testinclude --schema-class=DBICTestAdminInc --connect=[] --insert|);
cmp_ok ( $? >> 8, '==', 70, 'Correct exit code from connecting a custom INC schema' );

# test that config works properly
{
  no warnings 'qw';
  test_exec(qw|-It/lib/testinclude --schema-class=DBICTestConfig --create --connect=["klaatu","barada","nikto"]|);
  cmp_ok( $? >> 8, '==', 71, 'Correct schema loaded via config' ) || exit;
}

# test that config-file works properly
test_exec(qw|-It/lib/testinclude --schema-class=DBICTestConfig --config=t/lib/admincfgtest.json --config-stanza=Model::Gort --deploy|);
cmp_ok ($? >> 8, '==', 71, 'Correct schema loaded via testconfig');

eval { test_dbioadmin() };
diag $@ if $@;

done_testing();

sub test_dbioadmin {
    my $schema = DBICTest->init_schema( sqlite_use_file => 1 );  # reinit a fresh db for every run

    my $employees = $schema->resultset('Employee');

    test_exec( default_args(), qw|--op=insert --set={"name":"Matt"}| );
    ok( ($employees->count()==1), "insert count" );

    my $employee = $employees->find(1);
    ok( ($employee->name() eq 'Matt'), "insert valid" );

    test_exec( default_args(), qw|--op=update --set={"name":"Trout"}| );
    $employee = $employees->find(1);
    ok( ($employee->name() eq 'Trout'), "update" );

    test_exec( default_args(), qw|--op=insert --set={"name":"Aran"}| );

    SKIP: {
        skip ("MSWin32 doesn't support -|", 1) if $^O eq 'MSWin32';

        my ($perl) = $^X =~ /(.*)/;

        open(my $fh, "-|",  ( $perl, '-MDBICTest::RunMode', 'script/dbioadmin', default_args(), qw|--op=select --attrs={"order_by":"name"}| ) ) or die $!;
        my $data = do { local $/; <$fh> };
        close($fh);
        if (!ok( ($data=~/Aran.*Trout/s), "select with attrs" )) {
          diag ("data from select is $data")
        };
    }

    test_exec( default_args(), qw|--op=delete --where={"name":"Trout"}| );
    ok( ($employees->count()==1), "delete" );
}

sub default_args {
  my $json = JSON::MaybeXS->new(allow_nonref => 1);
  my $dsn = $json->encode([
    'dbi:SQLite:dbname=' . DBICTest->_sqlite_dbfilename,
    '',
    '',
    { AutoCommit => 1 },
  ]);

  return (
    qw|--quiet --schema-class=DBICTest::Schema --class=Employee|,
    qq|--connect=$dsn|,
    qw|--force -I testincludenoniterference|,
  );
}

sub test_exec {
  my ($perl) = $^X =~ /(.*)/;

  my @args = ($perl, '-MDBICTest::RunMode', File::Spec->catfile(qw(script dbioadmin)), @_);

  if ($^O eq 'MSWin32') {
    require Win32::ShellQuote; # included in test optdeps
    @args = Win32::ShellQuote::quote_system_list(@args);
  }

  system @args;
}
