package DBIO::ChangeLog::Table;
# ABSTRACT: Shared utilities for changelog table source definitions

use strict;
use warnings;

use Carp qw(croak);

=head1 DESCRIPTION

Shared utilities for L<DBIO::ChangeLog::Entry> and L<DBIO::ChangeLog::Set>.
Provides validation and building helpers for source_definition hashes.

=cut

sub validate_definition {
  my ($class, $def) = @_;
  croak "source_definition must return a hashref"
    unless ref $def eq 'HASH';

  for my $key (qw/ table columns column_order primary_key /) {
    croak "source_definition missing required key: $key"
      unless exists $def->{$key};
  }

  croak "columns must be a hashref"
    unless ref $def->{columns} eq 'HASH';

  croak "column_order must be an arrayref"
    unless ref $def->{column_order} eq 'ARRAY';

  croak "primary_key must be an arrayref"
    unless ref $def->{primary_key} eq 'ARRAY';

  return $def;
}

sub build_source {
  my ($class, $def) = @_;
  $class->validate_definition($def);

  return {
    table         => $def->{table},
    columns       => $def->{columns},
    column_order  => $def->{column_order},
    primary_key   => $def->{primary_key},
  };
}

1;

__END__

=head1 SEE ALSO

L<DBIO::ChangeLog::Entry>, L<DBIO::ChangeLog::Set>

=cut