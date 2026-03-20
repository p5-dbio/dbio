use strict;
use warnings;
use Test::More;

eval { require DBD::SQLite }
    or plan skip_all => 'DBD::SQLite required for naming tests';

eval { require DBIO::Loader }
    or plan skip_all => 'DBIO::Loader required';

use DBI;
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $tmpdir = tempdir(CLEANUP => 1);
my (undef, $db_file) = tempfile(SUFFIX => '.sqlite', UNLINK => 1, DIR => $tmpdir);
my $dsn = "dbi:SQLite:dbname=$db_file";

# Create tables with various naming patterns
my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
$dbh->do('CREATE TABLE artists (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('CREATE TABLE user_profiles (id INTEGER PRIMARY KEY, user_id INTEGER)');
$dbh->do('CREATE TABLE cd_tracks (id INTEGER PRIMARY KEY, cd_id INTEGER)');
$dbh->do('CREATE TABLE categories (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES categories(id))');
$dbh->do('CREATE TABLE person (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->disconnect;

# Test v8 naming: plurals singularized, CamelCase monikers
my $out_dir = File::Spec->catdir($tmpdir, 'naming');
mkdir $out_dir;

my $pid = fork();
die "fork: $!" unless defined $pid;
if (!$pid) {
    DBIO::Loader::make_schema_at('TestNaming::Schema', {
        dump_directory => $out_dir,
        quiet          => 1,
        generate_pod   => 0,
        naming         => 'current',
    }, [$dsn]);
    exit 0;
}
waitpid($pid, 0);
is($? >> 8, 0, 'Schema generated');

sub _slurp { open my $fh, '<', $_[0] or die "Cannot read $_[0]: $!"; local $/; <$fh> }

# Check that files exist with singularized CamelCase names
my $result_dir = "$out_dir/TestNaming/Schema/Result";

ok -f "$result_dir/Artist.pm",      'artists table -> Artist moniker (singularized)';
ok -f "$result_dir/UserProfile.pm",  'user_profiles table -> UserProfile moniker';
ok -f "$result_dir/CdTrack.pm",      'cd_tracks table -> CdTrack moniker';
ok -f "$result_dir/Category.pm",     'categories table -> Category moniker (singularized)';
ok -f "$result_dir/Person.pm",       'person table -> Person moniker (already singular)';

# Verify the table names in generated code still use original DB names
my $artist = _slurp("$result_dir/Artist.pm");
like $artist, qr/table.*"artists"/,
    'Artist class maps to "artists" table (original name preserved)';

my $user_profile = _slurp("$result_dir/UserProfile.pm");
like $user_profile, qr/table.*"user_profiles"/,
    'UserProfile maps to "user_profiles" table';

# Self-referential FK (categories.parent_id -> categories.id)
my $category = _slurp("$result_dir/Category.pm");
like $category, qr/belongs_to.*parent/s,
    'Category has belongs_to for self-referential FK';

done_testing;
