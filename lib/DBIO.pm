package DBIO;
# ABSTRACT: Native relational mapping for Perl, built on DBI

use strict;
use warnings;

our $VERSION = '0.900000';

use DBIO::Util;
use mro 'c3';

use DBIO::Optional::Dependencies;

use base qw/DBIO::Componentised DBIO::AccessorGroup/;
use DBIO::StartupCheck;
use DBIO::Exception;

__PACKAGE__->mk_group_accessors(inherited => '_skip_namespace_frames');
__PACKAGE__->_skip_namespace_frames('^DBIO|^SQL::Abstract|^Try::Tiny|^Class::Accessor::Grouped|^Context::Preserve');

# Formerly used to detect multiple DESTROY() invocations on the same object.
# This was added in DBIx::Class (commit e1d9e578, 2015) to protect against broken
# Perl/toolchain combinations (especially old Devel::StackTrace) that could cause
# destructors to be called more than once - a dangerous global condition.
#
# The detection had a performance cost: on every DESTROY it iterated over the entire
# destruction registry. With many objects this adds up (O(n) per destroy).
#
# Removed because modern Perl (5.14+) doesn't have these issues, and the overhead
# is not acceptable for large-scale row object destruction.
#
# If you encounter "multiple DESTROY" issues in production, your Perl or module
# stack is broken - fix that instead of re-enabling this.
#sub DESTROY { &DBIO::Util::detected_reinvoked_destructor }

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

1;

__END__

=encoding UTF-8

=head1 SYNOPSIS

The classes shown below can also be generated from an existing database with
L<dbiodump>, provided by L<DBIO::Loader>.

=head2 Schema class

  package MyApp::Schema;
  use base qw/DBIO::Schema/;

  __PACKAGE__->load_namespaces();

  1;

=head2 Vanilla style (classic)

  package MyApp::Schema::Result::Artist;
  use base qw/DBIO::Core/;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/ artistid name /);
  __PACKAGE__->set_primary_key('artistid');
  __PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artistid');

  1;

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
classic Vanilla style (C<< use base 'DBIO::Core' >>).

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
