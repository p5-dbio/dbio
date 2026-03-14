package DBIO::ChangeLog::Set;
# ABSTRACT: ResultSource for the changelog_set table

use strict;
use warnings;

=head1 DESCRIPTION

Defines the result source for the C<changelog_set> table, which groups
individual changelog entries into logical changesets (typically one per
transaction via L<DBIO::Schema::ChangeLog/txn_do>).

Each changeset records an optional user and session identifier along
with a creation timestamp.

=head1 COLUMN DEFINITIONS

=attr id

Integer primary key, auto-increment.

=attr user_id

Optional C<varchar(255)>. Set from L<DBIO::Schema::ChangeLog/changelog_user>.

=attr session_id

Optional C<varchar(255)>. Set from L<DBIO::Schema::ChangeLog/changelog_session>.

=attr created_at

C<datetime>, NOT NULL. Automatically set when the changeset is created.

=cut

sub source_definition {
  return {
    table   => 'changelog_set',
    columns => {
      id => {
        data_type         => 'integer',
        is_auto_increment => 1,
      },
      user_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
      },
      session_id => {
        data_type   => 'varchar',
        size        => 255,
        is_nullable => 1,
      },
      created_at => {
        data_type   => 'datetime',
        is_nullable => 0,
      },
    },
    column_order  => [qw/ id user_id session_id created_at /],
    primary_key   => ['id'],
  };
}

1;
