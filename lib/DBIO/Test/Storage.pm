package DBIO::Test::Storage;
# ABSTRACT: Fake storage for testing SQL generation without a database

use strict;
use warnings;

use base qw(DBIO::Storage::DBI);
use mro 'c3';

use DBIO::Storage::Statistics;

=head1 DESCRIPTION

A storage backend that generates SQL via L<DBIO::SQLMaker> but never
executes it against a real database.  Every query is captured and can
be inspected through L</captured_queries>.

This is useful for:

=over 4

=item *

Testing SQL generation (SELECT, INSERT, UPDATE, DELETE)

=item *

Verifying ResultSet chaining produces expected queries

=item *

Schema metadata tests (columns, relationships, constraints)

=item *

Any test that only cares about I<what> SQL would be generated

=back

=head1 SYNOPSIS

  my $schema = DBIO::Test::Schema->connect('DBIO::Test::Storage', '');
  my $rs = $schema->resultset('Artist')->search({ name => 'foo' });

  # .as_query works without a database
  my ($sql, @bind) = @{ ${$rs->as_query} };

  # or execute and capture
  my $storage = $schema->storage;
  $storage->reset_captured;
  $rs->all;  # generates SQL, returns empty results
  my @queries = $storage->captured_queries;

=cut

__PACKAGE__->sql_limit_dialect('GenericSubQ');

__PACKAGE__->mk_group_accessors(simple => qw(
  _captured_queries
  _fake_connected
));

sub new {
  my $self = shift->next::method(@_);
  $self->_captured_queries([]);
  $self->_fake_connected(1);
  $self->{_sql_maker_opts} ||= {};
  $self;
}

=method connected

Always returns true. There is no real connection to check.

=cut

sub connected { $_[0]->_fake_connected }

=method ensure_connected

No-op. We are always "connected".

=cut

sub ensure_connected { 1 }

sub _populate_dbh { }

=method disconnect

Sets connected state to false.

=cut

sub disconnect {
  my $self = shift;
  $self->_fake_connected(0);
  1;
}

# We don't have a real dbh, so never call anything that needs one
sub _dbh { undef }
sub _get_dbh { undef }
sub _server_info { { dbms_version => 0, normalized_dbms_version => 0 } }

sub _determine_driver { '' }
sub _init {}
sub _rebless {}
sub _seems_connected { $_[0]->_fake_connected }
sub _dbh_autocommit { 1 }

# Override txn_begin/commit/rollback to skip real dbh checks
sub txn_begin {
  my $self = shift;
  $self->next::method(@_);
}

sub txn_commit {
  my $self = shift;
  $self->throw_exception("Unable to txn_commit() on a disconnected storage")
    unless $self->_fake_connected;
  $self->next::method(@_);
}

sub txn_rollback {
  my $self = shift;
  $self->throw_exception("Unable to txn_rollback() on a disconnected storage")
    unless $self->_fake_connected;
  $self->next::method(@_);
}

=method _execute

Overrides L<DBIO::Storage::DBI/_execute> to capture the generated
SQL and bind values instead of executing them.

Returns an empty result set.

=cut

sub _execute {
  my ($self, $op, $ident, @args) = @_;

  my ($sql, $bind) = $self->_prep_for_execute($op, $ident, \@args);

  push @{ $self->_captured_queries }, {
    op   => $op,
    sql  => $sql,
    bind => $bind,
  };

  $self->_query_start($sql, $bind);
  $self->_query_end($sql, $bind);

  # Return values that match what DBI would return
  # ($rv, $sth, @bind) - we fake $sth with a minimal object
  my $fake_sth = DBIO::Test::Storage::FakeSth->new;
  return (wantarray ? ('0E0', $fake_sth, @{$bind||[]}) : '0E0');
}

=method captured_queries

Returns all captured queries as a list of hashrefs, each containing
C<op>, C<sql>, and C<bind> keys.

  my @queries = $storage->captured_queries;
  # ( { op => 'select', sql => 'SELECT ...', bind => [...] }, ... )

=cut

sub captured_queries {
  @{ $_[0]->_captured_queries || [] }
}

=method captured_sql_bind

Returns captured queries as arrayrefs of C<[$sql, @bind]> pairs,
compatible with L<SQL::Abstract::Test/is_same_sql_bind>.

=cut

sub captured_sql_bind {
  map { [ $_->{sql}, @{$_->{bind}||[]} ] } @{ $_[0]->_captured_queries || [] }
}

=method reset_captured

Clears the captured query log.

=cut

sub reset_captured {
  $_[0]->_captured_queries([]);
}

=method select

Returns a cursor that yields no rows.

=cut

sub select {
  my $self = shift;
  my ($ident, $select, $condition, $attrs) = @_;
  return DBIO::Test::Storage::FakeCursor->new($self, \@_, $attrs);
}

sub select_single {
  my $self = shift;
  my ($rv, $sth, @bind) = $self->_execute('select', @_);
  return ();
}

# Transaction tracking
sub _exec_txn_begin {
  push @{ $_[0]->_captured_queries }, { op => 'txn_begin', sql => 'BEGIN', bind => [] };
}

sub _exec_txn_commit {
  push @{ $_[0]->_captured_queries }, { op => 'txn_commit', sql => 'COMMIT', bind => [] };
}

sub _exec_txn_rollback {
  push @{ $_[0]->_captured_queries }, { op => 'txn_rollback', sql => 'ROLLBACK', bind => [] };
}

sub _exec_svp_begin {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_begin', sql => "SAVEPOINT $name", bind => [] };
}

sub _exec_svp_release {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_release', sql => "RELEASE SAVEPOINT $name", bind => [] };
}

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  push @{ $self->_captured_queries }, { op => 'svp_rollback', sql => "ROLLBACK TO SAVEPOINT $name", bind => [] };
}

# Deploy is a no-op
sub deploy { }

sub sqlt_type { 'NULL' }

# We handle last_insert_id by tracking inserts
sub last_insert_id { undef }
sub _dbh_last_insert_id { undef }

# No DBI bind attrs needed
sub _dbi_attrs_for_bind { [] }

# columns_info_for comes from the Result class definitions, no DB introspection
sub columns_info_for { {} }

# dbh_do without a real dbh - just run the coderef with undef dbh
sub dbh_do {
  my $self = shift;
  my $run_target = shift;

  if (not ref $run_target) {
    $self->$run_target(undef, @_);
  }
  else {
    $run_target->($self, undef, @_);
  }
}

# ---- Fake statement handle ----

{
  package # hide from PAUSE
    DBIO::Test::Storage::FakeSth;

  sub new { bless {}, shift }
  sub fetchrow_array { () }
  sub fetchrow_hashref { undef }
  sub finish { 1 }
  sub execute { '0E0' }
  sub bind_param { 1 }
  sub rows { 0 }
}

# ---- Fake cursor ----

{
  package # hide from PAUSE
    DBIO::Test::Storage::FakeCursor;

  use base 'DBIO::Cursor';

  sub new {
    my ($class, $storage, $args, $attrs) = @_;
    my $self = bless {
      storage => $storage,
      args    => $args,
      attrs   => $attrs,
    }, ref $class || $class;

    # Capture the select query
    my ($ident, $select, $condition, $a) = @$args;
    $storage->_execute('select', $ident, $select, $condition, $a || {});

    return $self;
  }

  sub next  { () }
  sub all   { () }
  sub reset { }
}

1;
