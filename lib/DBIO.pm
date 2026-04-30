package DBIO;
# ABSTRACT: Native relational mapping for Perl, built on DBI

use strict;
use warnings;

our $VERSION = '0.900000';

use DBIO::Base ();

sub import {
  my ($class, @args) = @_;
  my $caller = caller;

  my ($role, @opts);
  for my $arg (@args) {
    if (defined $arg && $arg =~ /^-/) { push @opts, $arg }
    elsif (!defined $role)            { $role = $arg }
    else                              { push @opts, $arg }
  }

  unless (defined $role) {
    if    ($caller =~ /::Result::[^:]+$/)    { $role = 'Core' }
    elsif ($caller =~ /::ResultSet::[^:]+$/) { $role = 'ResultSet' }
    else                                      { $role = 'Core' }
  }

  my $base = "DBIO::$role";
  eval "require $base; 1"
    or die "use DBIO '$role': cannot load $base: $@";

  {
    no strict 'refs';
    push @{"${caller}::ISA"}, $base unless $caller->isa($base);
  }

  strict->import;
  warnings->import;

  _apply_shortcut($caller, $_) for @opts;
}

sub _apply_shortcut {
  my ($caller, $opt) = @_;
  if ($opt eq '-pg') {
    eval "require DBIO::PostgreSQL::Result; 1"
      or die "use DBIO -pg: cannot load DBIO::PostgreSQL::Result: $@";
    eval { $caller->load_components('PostgreSQL::Result'); 1 }
      or die "use DBIO -pg: $@";
  }
  else {
    die "use DBIO: unknown shortcut '$opt'";
  }
}

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

The classes shown below can also be generated from an existing database with
L<dbiodump>, provided by L<DBIO::Loader>.

=head2 Schema class

  package MyApp::Schema;
  use DBIO 'Schema';

  __PACKAGE__->load_namespaces();

  1;

=head2 Vanilla style (import sugar)

  package MyApp::Schema::Result::Artist;
  use DBIO;    # Role is auto-detected from the package name: Core

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artistid');

  1;

The classic equivalent (still supported):

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';
  ...

=head2 Candy style (import sugar)

L<DBIO::Candy> removes the C<< __PACKAGE__-> >> boilerplate:

  package MyApp::Schema::Result::Artist;
  use DBIO::Candy;

  table 'artist';
  column artistid => { data_type => 'int', is_auto_increment => 1 };
  primary_key 'artistid';
  column name => { data_type => 'varchar', size => 100 };
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 Cake style (DDL-like DSL)

L<DBIO::Cake> provides type functions that read like DDL:

  package MyApp::Schema::Result::Artist;
  use DBIO::Cake;

  table 'artist';
  col artistid => integer, auto_inc;
  col name     => varchar(100);
  primary_key 'artistid';
  has_many cds => 'MyApp::Schema::Result::CD', 'artistid';

  1;

=head2 Using your schema

  use MyApp::Schema;
  my $schema = MyApp::Schema->connect($dbi_dsn, $user, $pass, \%dbi_params);

  my @all_artists = $schema->resultset('Artist')->all;

  my $johns_rs = $schema->resultset('Artist')->search(
    { name => { like => 'John%' } }
  );

  # Joins are automatic from relationship conditions
  my @rock_cds = $schema->resultset('CD')->search(
    { 'artist.name' => 'John Doe' }
  )->all;

  # Prefetch related data in a single query
  my $millennium_cds_rs = $schema->resultset('CD')->search(
    { year => 2000 },
    { prefetch => 'artist' }
  );

  my $cd = $millennium_cds_rs->next;
  my $artist_name = $cd->artist->name;  # no extra query

  # Create, update, delete
  my $new_cd = $schema->resultset('CD')->create({ title => 'Spoon' });
  $schema->txn_do(sub { $new_cd->update({ title => 'Fork' }) });
  $millennium_cds_rs->update({ year => 2002 });

=head1 DESCRIPTION

DBIO (DBI Objects) is a relational mapper for Perl built on top of L<DBI>.
It combines an object model for rows and result classes with a resultset API
for building queries without giving up database-native behavior.

Three styles are available for defining result classes:
L<DBIO::Cake> (DDL-like DSL), L<DBIO::Candy> (import sugar), and the
classic Vanilla style (C<use DBIO;> or C<< use base 'DBIO::Core' >>).

Database-specific features are provided by native driver distributions
(L<DBIO::PostgreSQL>, L<DBIO::MySQL>, L<DBIO::SQLite>, etc.) that speak
each database's dialect natively.

Key features:

=over 4

=item * Automatic joins from relationship conditions

=item * Lazy ResultSets that only query when you ask for rows

=item * Prefetch for efficient eager loading

=item * Multi-column primary and foreign keys

=item * Database-level paging, driver-specific SQL features

=item * Three result class styles: Cake, Candy, Vanilla

=back

B<DBIO is pre-1.0.> The core API is substantial and usable, but some edges
are still being refined. Please report anything that looks wrong or surprising.

=head1 USE-AS-PRAGMA

Since C<DBIO.pm> itself is a sugar pragma (analogous to C<Moose.pm>), it can
be used directly to declare a DBIO class. The role to inherit from is
auto-detected from the package name, or can be specified explicitly.

  package MyApp::Schema::Result::Artist;
  use DBIO;                    # -> @ISA = ('DBIO::Core')

  package MyApp::Schema::ResultSet::Artist;
  use DBIO;                    # -> @ISA = ('DBIO::ResultSet')

  package MyApp::Schema;
  use DBIO 'Schema';           # -> @ISA = ('DBIO::Schema')

  package MyApp::Schema::Result::Photo;
  use DBIO 'Core';             # explicit override

Shortcuts can be combined with role selection, separated by leading dashes:

  use DBIO -pg;                # Core + load DBIO::PostgreSQL component
  use DBIO 'Schema', -pg;      # Schema + load DBIO::PostgreSQL component

Role auto-detection rules:

=over 4

=item * package matches C<< /::Result::WORD$/ >> E<rarr> role C<Core>

=item * package matches C<< /::ResultSet::WORD$/ >> E<rarr> role C<ResultSet>

=item * anything else E<rarr> role C<Core> (the most common case)

=back

C<use DBIO;> additionally enables C<strict> and C<warnings> in the caller,
matching the behavior of L<DBIO::Candy>, L<DBIO::Cake>, L<DBIO::Moo> and
L<DBIO::Moose>.

=head1 WHERE TO START

See L<DBIO::Manual::DocMap> for the full documentation map. New users should
start with L<DBIO::Manual::QuickStart>.

=head1 HERITAGE

DBIO is a fork of L<DBIx::Class> with a clean namespace break. Key changes:

=over 4

=item * Namespace: C<DBIO::> replaces C<DBIx::Class::>

=item * L<SQL::Abstract> replaces L<SQL::Abstract::Classic>

=item * LIMIT/OFFSET via C<apply_limit> on the driver's SQLMaker instead of
string-based dialect dispatch

=item * L<SQL::Translator> is optional, being replaced by DB-specific deploy
modules

=item * L<DBIx::Class::TimeStamp> and L<DBIx::Class::Helpers> functionality
integrated into core

=item * Native driver distributions for each database (L<DBIO::PostgreSQL>,
L<DBIO::MySQL>, L<DBIO::SQLite>) replace the monolithic DBIx::Class storage
layer; SQL::Translator is no longer required for schema management

=item * Meta-infrastructure has been split into L<DBIO::Base> (inherited by
all internal classes); C<DBIO.pm> is now a pure sugar pragma

=back

=head1 GETTING HELP

=over

=item * GitHub Issues: L<https://github.com/p5-dbio/dbio/issues>

=item * IRC: C<#dbio> on C<irc.perl.org>

=back

=head1 CONTRIBUTING

Contributions are welcome: bug reports, documentation improvements, pull
requests, or patches.

=over

=item * Repository: L<https://github.com/p5-dbio/dbio>

=back

=head1 AUTHORS

DBIO is built on top of L<DBIx::Class>, which was a long-running collaborative
effort by many contributors. See the F<AUTHORS> file for the full list.
