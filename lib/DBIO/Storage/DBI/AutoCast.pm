package DBIO::Storage::DBI::AutoCast;
# ABSTRACT: Storage component for RDBMS requiring explicit placeholder typing

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->mk_group_accessors('simple' => 'auto_cast' );

=head1 SYNOPSIS

  $schema->storage->auto_cast(1);

=head1 DESCRIPTION

In some combinations of RDBMS and DBD drivers (e.g. FreeTDS and Sybase)
statements with values bound to columns or conditions that are not strings will
throw implicit type conversion errors.

As long as a column L<data_type|DBIO::ResultSource/add_columns> is
defined and resolves to a base RDBMS native type via
L<_native_data_type|DBIO::Storage::DBI/_native_data_type> as
defined in your Storage driver, the placeholder for this column will be
converted to:

  CAST(? as $mapped_type)

This option can also be enabled in
L<connect_info|DBIO::Storage::DBI/connect_info> as:

  on_connect_call => ['set_auto_cast']

=cut

sub _prep_for_execute {
  my $self = shift;

  my ($sql, $bind) = $self->next::method (@_);

# If we're using ::NoBindVars, there are no binds by this point so this code
# gets skipped.
  if ($self->auto_cast && @$bind) {
    my $new_sql;
    my @sql_part = split /\?/, $sql, scalar @$bind + 1;
    for (@$bind) {
      my $cast_type = $self->_native_data_type($_->[0]{sqlt_datatype});
      $new_sql .= shift(@sql_part) . ($cast_type ? "CAST(? AS $cast_type)" : '?');
    }
    $sql = $new_sql . shift @sql_part;
  }

  return ($sql, $bind);
}

=head2 connect_call_set_auto_cast

Executes:

  $schema->storage->auto_cast(1);

on connection.

Used as:

    on_connect_call => ['set_auto_cast']

in L<connect_info|DBIO::Storage::DBI/connect_info>.

=cut

sub connect_call_set_auto_cast {
  my $self = shift;
  $self->auto_cast(1);
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
