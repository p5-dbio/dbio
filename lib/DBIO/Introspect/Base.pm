package DBIO::Introspect::Base;
# ABSTRACT: Base class for DBIO driver introspectors
our $VERSION = '0.900000';

use strict;
use warnings;

=head1 DESCRIPTION

Base class for the driver-specific introspectors
(L<DBIO::PostgreSQL::Introspect>, L<DBIO::SQLite::Introspect>,
L<DBIO::MySQL::Introspect>). Provides C<new>, the C<dbh> accessor, and the
lazy C<model> builder. Subclasses must implement C<_build_model>.

=cut

sub new {
  my ($class, %args) = @_;
  bless \%args, $class;
}

=attr dbh

The connected C<DBI> database handle. Required.

=cut

sub dbh { $_[0]->{dbh} }

=method model

The introspected database model hashref. Built lazily on first access via
L</_build_model>. The shape varies by driver.

=cut

sub model { $_[0]->{model} //= $_[0]->_build_model }

sub _build_model {
  my ($self) = @_;
  die ref($self) . '::_build_model not implemented';
}

=method _aggregate_by

    my $by_table = $class->_aggregate_by(\@rows, 'table_name');

Groups a flat array of row hashrefs into C<{ $key_value => [\%row, ...] }>.
Preserves row order within each group. The C<\@rows> arrayref is consumed
(rows are shifted off); pass a copy if you need the original.

=cut

sub _aggregate_by {
  my ($class, $rows, $key_field) = @_;
  my %result;
  for my $row (@{ $rows // [] }) {
    my $key = $row->{$key_field} // next;
    push @{ $result{$key} }, $row;
  }
  return \%result;
}

1;
