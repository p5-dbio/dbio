use strict;
use warnings;
use Test::More;

eval { require DBD::SQLite }
    or plan skip_all => 'DBD::SQLite required for relationship tests';

eval { require DBIO::Loader }
    or plan skip_all => 'DBIO::Loader required';

use DBI;
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $tmpdir = tempdir(CLEANUP => 1);
my (undef, $db_file) = tempfile(SUFFIX => '.sqlite', UNLINK => 1, DIR => $tmpdir);
my $dsn = "dbi:SQLite:dbname=$db_file";

# Create a realistic schema with various relationship types
my $dbh = DBI->connect($dsn, '', '', { RaiseError => 1 });
$dbh->do('PRAGMA foreign_keys = ON');

# Basic one-to-many: artist has many cds
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
$dbh->do('CREATE TABLE cd (
    id INTEGER PRIMARY KEY,
    artist_id INTEGER NOT NULL REFERENCES artist(id),
    title TEXT NOT NULL
)');

# One-to-many through: cd has many tracks
$dbh->do('CREATE TABLE track (
    id INTEGER PRIMARY KEY,
    cd_id INTEGER NOT NULL REFERENCES cd(id),
    title TEXT NOT NULL,
    position INTEGER
)');

# Many-to-many via link table: cd <-> tag
$dbh->do('CREATE TABLE tag (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
$dbh->do('CREATE TABLE cd_tag (
    cd_id INTEGER NOT NULL REFERENCES cd(id),
    tag_id INTEGER NOT NULL REFERENCES tag(id),
    PRIMARY KEY (cd_id, tag_id)
)');

# Self-referential: employee has a manager (also an employee)
$dbh->do('CREATE TABLE employee (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    manager_id INTEGER REFERENCES employee(id)
)');

# Multiple FKs to same table: message has sender and recipient (both users)
$dbh->do('CREATE TABLE app_user (id INTEGER PRIMARY KEY, name TEXT NOT NULL)');
$dbh->do('CREATE TABLE message (
    id INTEGER PRIMARY KEY,
    sender_id INTEGER NOT NULL REFERENCES app_user(id),
    recipient_id INTEGER NOT NULL REFERENCES app_user(id),
    body TEXT
)');

$dbh->disconnect;

sub _slurp { open my $fh, '<', $_[0] or die "Cannot read $_[0]: $!"; local $/; <$fh> }

# Generate with vanilla style
my $out_dir = File::Spec->catdir($tmpdir, 'rels');
mkdir $out_dir;

my $pid = fork();
die "fork: $!" unless defined $pid;
if (!$pid) {
    DBIO::Loader::make_schema_at('TestRels::Schema', {
        dump_directory => $out_dir,
        quiet          => 1,
        generate_pod   => 0,
        naming         => 'current',
    }, [$dsn]);
    exit 0;
}
waitpid($pid, 0);
is($? >> 8, 0, 'Schema generated');

my $result_dir = "$out_dir/TestRels/Schema/Result";

# --- One-to-many: Artist -> CD ---
my $artist = _slurp("$result_dir/Artist.pm");
like $artist, qr/has_many.*cds/s,
    'Artist has_many cds';

my $cd = _slurp("$result_dir/Cd.pm");
like $cd, qr/belongs_to.*artist/s,
    'CD belongs_to artist';

# --- One-to-many chain: CD -> Track ---
like $cd, qr/has_many.*tracks/s,
    'CD has_many tracks';

my $track = _slurp("$result_dir/Track.pm");
like $track, qr/belongs_to.*cd/s,
    'Track belongs_to cd';

# --- Many-to-many: CD <-> Tag via cd_tag ---
my $cd_tag = _slurp("$result_dir/CdTag.pm");
like $cd_tag, qr/belongs_to.*cd/s,
    'CdTag belongs_to cd';
like $cd_tag, qr/belongs_to.*tag/s,
    'CdTag belongs_to tag';

# The link table should create m2m relationships on both sides
like $cd, qr/many_to_many.*tags/s,
    'CD many_to_many tags (through cd_tags)';

my $tag = _slurp("$result_dir/Tag.pm");
like $tag, qr/has_many.*cd_tags/s,
    'Tag has_many cd_tags';

# --- Self-referential: Employee -> Manager ---
my $employee = _slurp("$result_dir/Employee.pm");
like $employee, qr/belongs_to.*manager/s,
    'Employee belongs_to manager';
like $employee, qr/has_many.*employee/si,
    'Employee has_many employees (reverse self-ref)';

# --- Multiple FKs to same table: Message -> AppUser ---
my $message = _slurp("$result_dir/Message.pm");
like $message, qr/belongs_to.*sender/s,
    'Message belongs_to sender';
like $message, qr/belongs_to.*recipient/s,
    'Message belongs_to recipient';

# Both should point to AppUser
my $app_user = _slurp("$result_dir/AppUser.pm");
# AppUser should have has_many for both sender and recipient messages
my @has_many_matches = ($app_user =~ /has_many/g);
cmp_ok scalar @has_many_matches, '>=', 2,
    'AppUser has at least 2 has_many relationships (sender + recipient messages)';

done_testing;
