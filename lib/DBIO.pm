package DBIO;
# ABSTRACT: Native relational mapping for Perl, built on DBI

use strict;
use warnings;

our $VERSION;
# Always remember to do all digits for the version even if they're 0
# i.e. first release of 0.XX *must* be 0.XX000. This avoids fBSD ports
# brain damage and presumably various other packaging systems too

# $VERSION declaration must stay up here, ahead of any other package
# declarations, as to not confuse various modules attempting to determine
# this ones version, whether that be s.c.o. or Module::Metadata, etc
$VERSION = '0.900000';

{
  package
    DBIO::_ENV_;

  require constant;
  constant->import( DEVREL => ( ($DBIO::VERSION =~ /_/) ? 1 : 0 ) );
}

$VERSION = eval $VERSION if $VERSION =~ /_/; # numify for warning-free dev releases

use DBIO::Util;
use mro 'c3';

use DBIO::Optional::Dependencies;

use base qw/DBIO::Componentised DBIO::AccessorGroup/;
use DBIO::StartupCheck;
use DBIO::Exception;

__PACKAGE__->mk_group_accessors(inherited => '_skip_namespace_frames');
__PACKAGE__->_skip_namespace_frames('^DBIO|^SQL::Abstract|^Try::Tiny|^Class::Accessor::Grouped|^Context::Preserve');

# FIXME - this is not really necessary, and is in
# fact going to slow things down a bit
# However it is the right thing to do in order to get
# various install bases to highlight their brokenness
# Remove at some unknown point in the future
sub DESTROY { &DBIO::Util::detected_reinvoked_destructor }

sub mk_classdata {
  shift->mk_classaccessor(@_);
}

sub mk_classaccessor {
  my $self = shift;
  $self->mk_group_accessors('inherited', $_[0]);
  $self->set_inherited(@_) if @_ > 1;
}

sub component_base_class { 'DBIO' }

sub MODIFY_CODE_ATTRIBUTES {
  my ($class,$code,@attrs) = @_;
  $class->mk_classdata('__attr_cache' => {})
    unless $class->can('__attr_cache');
  $class->__attr_cache->{$code} = [@attrs];
  return ();
}

sub _attr_cache {
  my $self = shift;
  my $cache = $self->can('__attr_cache') ? $self->__attr_cache : {};

  return {
    %$cache,
    %{ $self->maybe::next::method || {} },
  };
}

# *DO NOT* change this URL nor the identically named =head1 below
# it is linked throughout the ecosystem
sub DBIO::_ENV_::HELP_URL () {
  'https://github.com/p5-dbio/dbio/issues'
}

1;

__END__

# This is the only file where an explicit =encoding is needed,
# as the distbuild-time injected author list is utf8 encoded
# Without this pod2text output is less than ideal
#
# A bit regarding selection/compatiblity:
# Before 5.8.7 UTF-8 was == utf8, both behaving like the (lax) utf8 we know today
# Then https://www.nntp.perl.org/group/perl.unicode/2004/12/msg2705.html happened
# Encode way way before 5.8.0 supported UTF-8: https://metacpan.org/source/DANKOGAI/Encode-1.00/lib/Encode/Supported.pod#L44
# so it is safe for the oldest toolchains.
# Additionally we inject all the utf8 programattically and test its well-formedness
# so all is well
#
=encoding UTF-8

=head1 EARLY VERSION WARNING

B<DBIO is still pre-1.0.> The core API is already substantial and largely
compatible with L<DBIx::Class>, but some edges are still being refined as the
split driver ecosystem settles down. Please report anything that looks wrong,
surprising, or incomplete.

=head1 KEY DIFFERENCES FROM DBIx::Class

DBIO is a fork of L<DBIx::Class> with a clean break. If you are migrating
code or porting workarounds, pay attention to these changes:

=over 4

=item * Namespace: C<DBIO::> replaces C<DBIx::Class::>

=item * L<SQL::Abstract> replaces L<SQL::Abstract::Classic>

=item * B<LIMIT/OFFSET>: The C<sql_limit_dialect> accessor, the string-based
C<limit_dialect> dispatch, and the C<emulate_limit()> hook have been removed.
Each database driver's SQLMaker now provides an
L<apply_limit|DBIO::SQLMaker::ClassicExtensions/apply_limit> method instead.
The default is C<LIMIT ? OFFSET ?>. If you had custom limit logic, override
C<apply_limit> on your SQLMaker subclass.

=item * L<SQL::Translator> is optional — being replaced by DB-specific
deploy modules (e.g. L<DBIO::PostgreSQL::Deploy>)

=item * L<DBIx::Class::TimeStamp> and L<DBIx::Class::Helpers> functionality
integrated into core

=back

=head1 WHERE TO START READING

See L<DBIO::Manual::DocMap> for the documentation map.
If you are new to DBIO, start with the
L<manuals|DBIO::Manual::DocMap/Manuals> in the order listed there.

=cut

=head1 GETTING HELP/SUPPORT

DBIO covers a large problem space, so questions are inevitable once you start
using it in anger. If you are stuck, or you are unsure whether a particular
approach fits DBIO well, use one of the following channels:

=over

=item * IRC: C<#dbio> on C<irc.perl.org> (highlight Getty for quicker answer)

=item * GitHub Issues: L<https://github.com/p5-dbio/dbio/issues>

=back

=head1 SYNOPSIS

For the shortest path, start with L<DBIO::Manual::QuickStart>.

The classes shown below can also be generated from an existing database with
L<dbiodump>, which is provided by L<DBIO::Loader>.

=head2 Schema classes preparation

Create a schema class called F<MyApp/Schema.pm>:

  package MyApp::Schema;
  use base qw/DBIO::Schema/;

  __PACKAGE__->load_namespaces();

  1;

Create a result class to represent artists, who have many CDs, in
F<MyApp/Schema/Result/Artist.pm>:

See L<DBIO::ResultSource> for docs on defining result classes.

  package MyApp::Schema::Result::Artist;
  use base qw/DBIO::Core/;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artistid');

  1;

A result class to represent a CD, which belongs to an artist, in
F<MyApp/Schema/Result/CD.pm>:

  package MyApp::Schema::Result::CD;
  use base qw/DBIO::Core/;

  __PACKAGE__->load_components(qw/InflateColumn::DateTime/);
  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(qw/ cdid artistid title year /);
  __PACKAGE__->set_primary_key('cdid');
  __PACKAGE__->belongs_to(artist => 'MyApp::Schema::Result::Artist', 'artistid');

  1;

=head2 Alternative: Sugar syntax with DBIO::Candy

L<DBIO::Candy> removes the C<< __PACKAGE__-> >> boilerplate:

  package MyApp::Schema::Result::Artist;
  use DBIO::Candy;

  table 'artist';
  column artistid => { data_type => 'int', is_auto_increment => 1 };
  primary_key 'artistid';
  column name => { data_type => 'varchar', size => 100 };
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 Alternative: DDL-like syntax with DBIO::Cake

L<DBIO::Cake> provides type functions that read like DDL:

  package MyApp::Schema::Result::Artist;
  use DBIO::Cake;

  table 'artist';
  col artistid => integer, auto_inc;
  col name     => varchar(100);
  primary_key 'artistid';
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 API usage

You can then use these classes in your application code:

  # Connect to your database.
  use MyApp::Schema;
  my $schema = MyApp::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

  # Query for all artists and put them in an array,
  # or retrieve them as a result set object.
  # $schema->resultset returns a DBIO::ResultSet
  my @all_artists = $schema->resultset('Artist')->all;
  my $all_artists_rs = $schema->resultset('Artist');

  # Output all artists names
  # $artist here is a DBIO::Row, which has accessors
  # for all its columns. Rows are also subclasses of your Result class.
  foreach $artist (@all_artists) {
    print $artist->name, "\n";
  }

  # Create a result set to search for artists.
  # This does not query the DB.
  my $johns_rs = $schema->resultset('Artist')->search(
    # Build your WHERE using an SQL::Abstract-compatible structure:
    { name => { like => 'John%' } }
  );

  # Execute a joined query to get the cds.
  my @all_john_cds = $johns_rs->search_related('cds')->all;

  # Joins are automatic — just reference the relationship in conditions:
  my @rock_cds = $schema->resultset('CD')->search(
    { 'artist.name' => 'John Doe' }  # join added automatically
  )->all;

  # Fetch the next available row.
  my $first_john = $johns_rs->next;

  # Specify ORDER BY on the query.
  my $first_john_cds_by_title_rs = $first_john->cds(
    undef,
    { order_by => 'title' }
  );

  # Create a result set that will fetch the artist data
  # at the same time as it fetches CDs, using only one query.
  my $millennium_cds_rs = $schema->resultset('CD')->search(
    { year => 2000 },
    { prefetch => 'artist' }
  );

  my $cd = $millennium_cds_rs->next; # SELECT ... FROM cds JOIN artists ...
  my $cd_artist_name = $cd->artist->name; # Already has the data so no 2nd query

  # new() makes a Result object but doesn't insert it into the DB.
  # create() is the same as new() then insert().
  my $new_cd = $schema->resultset('CD')->new({ title => 'Spoon' });
  $new_cd->artist($cd->artist);
  $new_cd->insert; # Auto-increment primary key filled in after INSERT
  $new_cd->title('Fork');

  $schema->txn_do(sub { $new_cd->update }); # Runs the update in a transaction

  # change the year of all the millennium CDs at once
  $millennium_cds_rs->update({ year => 2002 });

=head1 DESCRIPTION

DBIO (DBI Objects) is a relational mapper for Perl built on top of L<DBI>. It
combines an object model for rows and result classes with a resultset API for
building queries without giving up database-native behavior.

DBIO automatically discovers joins from search conditions — when you
reference a relationship in a condition (e.g. C<< 'artist.name' => 'Fred' >>),
the required join is added without needing an explicit C<< join => >> attribute.

Three styles are available for defining result classes:
L<DBIO::Cake> (DDL-like DSL), L<DBIO::Candy> (import sugar), and the
classic Vanilla style (C<< use base 'DBIO::Core' >>). Database-specific
features are provided by fully native driver distributions
(L<DBIO-PostgreSQL|DBIO::PostgreSQL>, L<DBIO-MySQL|DBIO::MySQL>,
L<DBIO-SQLite|DBIO::SQLite>, etc.) that speak each database's dialect.

DBIO handles multi-column primary and foreign keys, complex query trees,
database-level paging, and driver-specific SQL features. ResultSets stay lazy
until you ask for rows or aggregates, and iterator-style access only fetches
rows as needed to keep memory usage predictable. Auto-increment and
insert-returning behavior are delegated to the active driver so PostgreSQL,
MySQL, SQLite, Oracle, and other backends can expose their native strengths.

Large new features may still be marked B<experimental>. That means the feature
is intended to be used, but the API or edge-case behavior may still move as
real-world feedback arrives. Reproducible failing tests are always welcome.

Published APIs should remain stable. When something breaks unexpectedly, report
it; even non-public regressions are often fixed if they can be corrected
without making the rest of the code worse.

The test suite is intentionally broad, and developer releases are expected as
the core and driver distributions continue to converge on a stable 1.0 shape.

=head1 HOW TO CONTRIBUTE

Contributions are always welcome, in all usable forms (we especially
welcome documentation improvements). The delivery methods include git-
or unified-diff formatted patches, GitHub pull requests, or plain bug
reports via L<GitHub Issues|https://github.com/p5-dbio/dbio/issues>.
Do not hesitate to
L<get in touch|/GETTING HELP/SUPPORT> with any further questions you may
have.

This project is maintained in a git repository. The code and related tools are
accessible at the following locations:

=over

=item * Current git repository: L<https://github.com/p5-dbio/dbio>

=back

=head1 AUTHORS

Even though a large portion of the source I<appears> to be written by just a
handful of people, this library continues to remain a collaborative effort -
perhaps one of the most successful such projects on L<CPAN|http://cpan.org>.
It is important to remember that ideas do not always result in a direct code
contribution, but deserve acknowledgement just the same. Time and time again
the seemingly most insignificant questions and suggestions have been shown
to catalyze monumental improvements in consistency, accuracy and performance.

=for comment this line is replaced with the author list at dist-building time

The canonical source of authors and their details is the F<AUTHORS> file at
the root of this distribution (or repository). The canonical source of
per-line authorship is the L<git repository|/HOW TO CONTRIBUTE> history
itself.
