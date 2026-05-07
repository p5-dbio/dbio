package DBIO::ChangeLog::Entry;
# ABSTRACT: ResultSource definition for per-source changelog tables

use strict;
use warnings;

use DBIO::ChangeLog::Table;

=head1 DESCRIPTION

Defines the base column layout for C<< <source>_changelog >> tables.
Each tracked ResultSource gets its own changelog table with these columns.

The L<DBIO::ChangeLog::Schema> component uses this definition when
dynamically creating changelog ResultSource objects at schema composition
time.

=head1 COLUMN DEFINITIONS

=attr id

Integer primary key, auto-increment.

=attr changeset_id

Optional integer FK pointing to L<DBIO::ChangeLog::Set/id>.  NULL for
custom events logged outside a transaction.

=attr row_id

C<varchar(255)> containing the serialized primary key of the tracked
row.  Single-column PKs store the value directly; multi-column PKs
use a JSON array.

=attr event

C<varchar(64)> identifying the operation: C<insert>, C<update>,
C<delete>, or a custom event name.

=attr changes

C<text> column containing JSON-encoded change data.  The format depends
on the event type (see L<DBIO::ChangeLog> for details).

=attr created_at

C<datetime>, NOT NULL. Automatically set when the entry is created.

=cut

sub source_definition {
  my ($class, %args) = @_;
  my $table = $args{table};
  require Carp;
  Carp::croak("source_definition requires 'table' argument")
    unless defined $table && length $table;

  return DBIO::ChangeLog::Table->build_source({
    table   => "${table}_changelog",
    columns => {
      id => {
        data_type         => 'integer',
        is_auto_increment => 1,
      },
      changeset_id => {
        data_type   => 'integer',
        is_nullable => 1,
      },
      row_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 0,
      },
      event => {
        data_type   => 'varchar',
        size        => 64,
        is_nullable => 0,
      },
      changes => {
        data_type   => 'text',
        is_nullable => 1,
      },
      created_at => {
        data_type   => 'datetime',
        is_nullable => 0,
      },
    },
    column_order  => [qw/ id changeset_id row_id event changes created_at /],
    primary_key   => ['id'],
  });
}

1;

__END__

=head1 SEE ALSO

L<DBIO::ChangeLog>, L<DBIO::ChangeLog::Schema>, L<DBIO::ChangeLog::Table>

=cut