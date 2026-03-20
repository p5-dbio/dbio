use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir tempfile);
use File::Spec;

# Test code generation for all three styles: vanilla, cake, candy
# Uses a file-based SQLite database and separate processes to avoid
# class loading conflicts between styles.

eval { require DBD::SQLite }
    or plan skip_all => 'DBD::SQLite required for code generation tests';

eval { require DBIO::Loader }
    or plan skip_all => 'DBIO::Loader required';

use DBI;

my $tmpdir = tempdir(CLEANUP => 1);

# Create a simple test database
my (undef, $db_file) = tempfile(SUFFIX => '.sqlite', UNLINK => 1, DIR => $tmpdir);
my $dsn = "dbi:SQLite:dbname=$db_file";
my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
$dbh->do(q{
    CREATE TABLE artist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name VARCHAR(128) NOT NULL,
        bio TEXT
    )
});
$dbh->do(q{
    CREATE TABLE cd (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artist_id INTEGER NOT NULL REFERENCES artist(id),
        title VARCHAR(256) NOT NULL,
        year INTEGER
    )
});
$dbh->do(q{CREATE UNIQUE INDEX idx_artist_name ON artist(name)});
$dbh->disconnect;

# Helper: run make_schema_at in a child process to avoid class conflicts
sub _generate {
    my ($schema_class, $opts, $dsn) = @_;
    my $pid = fork();
    die "fork failed: $!" unless defined $pid;
    if (!$pid) {
        DBIO::Loader::make_schema_at($schema_class, $opts, [$dsn]);
        exit 0;
    }
    waitpid($pid, 0);
    is($? >> 8, 0, "Generated $schema_class");
}

sub _slurp {
    open my $fh, '<', $_[0] or die "Cannot read $_[0]: $!";
    local $/; <$fh>;
}

# --- Vanilla style ---

my $vanilla_dir = File::Spec->catdir($tmpdir, 'vanilla');
mkdir $vanilla_dir;
_generate('TestVanilla::Schema', {
    dump_directory => $vanilla_dir,
    quiet          => 1,
    generate_pod   => 0,
    naming         => 'current',
}, $dsn);

my $vanilla_artist = _slurp("$vanilla_dir/TestVanilla/Schema/Result/Artist.pm");

like $vanilla_artist, qr/use base 'DBIO::Core'/,
    'vanilla: uses base DBIO::Core';
like $vanilla_artist, qr/__PACKAGE__->table\("artist"\)/,
    'vanilla: __PACKAGE__->table call';
like $vanilla_artist, qr/__PACKAGE__->add_columns/,
    'vanilla: __PACKAGE__->add_columns call';
like $vanilla_artist, qr/__PACKAGE__->set_primary_key\("id"\)/,
    'vanilla: __PACKAGE__->set_primary_key call';

my $vanilla_cd = _slurp("$vanilla_dir/TestVanilla/Schema/Result/Cd.pm");
like $vanilla_cd, qr/__PACKAGE__->belongs_to/,
    'vanilla: belongs_to relationship';
like $vanilla_cd, qr/artist_id/,
    'vanilla: FK column present';

# --- Cake style ---

my $cake_dir = File::Spec->catdir($tmpdir, 'cake');
mkdir $cake_dir;
_generate('TestCake::Schema', {
    dump_directory => $cake_dir,
    quiet          => 1,
    generate_pod   => 0,
    naming         => 'current',
    loader_style   => 'cake',
}, $dsn);

my $cake_artist = _slurp("$cake_dir/TestCake/Schema/Result/Artist.pm");

like $cake_artist, qr/use DBIO::Cake/,
    'cake: uses DBIO::Cake';
unlike $cake_artist, qr/use base/,
    'cake: no use base';
like $cake_artist, qr/^table "artist";/m,
    'cake: table DSL';
like $cake_artist, qr/^col id => /m,
    'cake: col DSL for id';
like $cake_artist, qr/^col name => varchar\(128\)/m,
    'cake: col DSL for name with size';
like $cake_artist, qr/^col bio => text, null/m,
    'cake: col DSL for bio with null';
like $cake_artist, qr/^primary_key "id"/m,
    'cake: primary_key DSL';
unlike $cake_artist, qr/__PACKAGE__->add_columns/,
    'cake: no __PACKAGE__->add_columns';

my $cake_cd = _slurp("$cake_dir/TestCake/Schema/Result/Cd.pm");
like $cake_cd, qr/^belongs_to /m,
    'cake: belongs_to relationship';
like $cake_cd, qr/^col artist_id => integer, fk/m,
    'cake: FK column with fk modifier';

# --- Candy style ---

my $candy_dir = File::Spec->catdir($tmpdir, 'candy');
mkdir $candy_dir;
_generate('TestCandy::Schema', {
    dump_directory => $candy_dir,
    quiet          => 1,
    generate_pod   => 0,
    naming         => 'current',
    loader_style   => 'candy',
}, $dsn);

my $candy_artist = _slurp("$candy_dir/TestCandy/Schema/Result/Artist.pm");

like $candy_artist, qr/use DBIO::Candy/,
    'candy: uses DBIO::Candy';
unlike $candy_artist, qr/use base/,
    'candy: no use base';
like $candy_artist, qr/^table "artist";/m,
    'candy: table DSL';
like $candy_artist, qr/^has_column id => /m,
    'candy: has_column for id';
like $candy_artist, qr/^has_column name => 'varchar'/m,
    'candy: has_column for name';
like $candy_artist, qr/^primary_key "id"/m,
    'candy: primary_key DSL';

my $candy_cd = _slurp("$candy_dir/TestCandy/Schema/Result/Cd.pm");
like $candy_cd, qr/^belongs_to /m,
    'candy: belongs_to relationship';

done_testing;
