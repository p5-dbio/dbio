use strict;
use warnings;

use Test::More;
plan skip_all => 'Test requires a real database connection (use DBIO::SQLite test suite)';

use lib qw(t/lib);

my $schema = DBICTest->init_schema();

{
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, @_; };
    {
        # Test that this doesn't cause infinite recursion.
        local *DBICTest::Artist::DESTROY;
        local *DBICTest::Artist::DESTROY = sub { $_[0]->discard_changes };

        my $artist = $schema->resultset("Artist")->create( {
            artistid    => 10,
            name        => "artist number 10",
        });

        $artist->name("Wibble");

        print "# About to call DESTROY\n";
    }
    is_deeply \@warnings, [];
}

done_testing;
