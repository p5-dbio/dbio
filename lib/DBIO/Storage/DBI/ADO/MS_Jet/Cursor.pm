package DBIO::Storage::DBI::ADO::MS_Jet::Cursor;

use strict;
use warnings;
use base 'DBIO::Storage::DBI::Cursor';
use mro 'c3';
use DBIO::Storage::DBI::ADO::CursorUtils '_normalize_guids';
use namespace::clean;

=head1 NAME

DBIO::Storage::DBI::ADO::MS_Jet::Cursor - GUID Support for MS Access over
ADO

=head1 DESCRIPTION

This class is for normalizing GUIDs retrieved from Microsoft Access over ADO.

You probably don't want to be here, see
L<DBIO::Storage::DBI::ACCESS> for information on the Microsoft
Access driver.

Unfortunately when using L<DBD::ADO>, GUIDs come back wrapped in braces, the
purpose of this class is to remove them.
L<DBIO::Storage::DBI::ADO::MS_Jet> sets
L<cursor_class|DBIO::Storage::DBI/cursor_class> to this class by default.
It is overridable via your
L<connect_info|DBIO::Storage::DBI/connect_info>.

You can use L<DBIO::Cursor::Cached> safely with this class and not lose
the GUID normalizing functionality,
L<::Cursor::Cached|DBIO::Cursor::Cached> uses the underlying class data
for the inner cursor class.

=cut

sub next {
  my $self = shift;

  my @row = $self->next::method(@_);

  _normalize_guids(
    $self->args->[1],
    $self->{_colinfos} ||= $self->storage->_resolve_column_info($self->args->[0]),
    \@row,
    $self->storage
  );

  return @row;
}

sub all {
  my $self = shift;

  my @rows = $self->next::method(@_);

  _normalize_guids(
    $self->args->[1],
    $self->{_colinfos} ||= $self->storage->_resolve_column_info($self->args->[0]),
    $_,
    $self->storage
  ) for @rows;

  return @rows;
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

# vim:sts=2 sw=2:
