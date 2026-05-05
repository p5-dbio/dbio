package DBIO::Diff::Base;
# ABSTRACT: Base class for DBIO driver diff orchestrators
our $VERSION = '0.900000';

use strict;
use warnings;

=head1 DESCRIPTION

Base class for driver-specific diff orchestrators
(L<DBIO::PostgreSQL::Diff>, L<DBIO::SQLite::Diff>, L<DBIO::MySQL::Diff>).
Provides the full public interface; subclasses implement only
C<_build_operations>.

=cut

sub new { my ($class, %args) = @_; bless \%args, $class }

sub source { $_[0]->{source} }

=attr source

The current (live) database model hashref. Required.

=cut

sub target { $_[0]->{target} }

=attr target

The desired (deployed from DBIO classes) database model hashref. Required.

=cut

sub operations { $_[0]->{operations} //= $_[0]->_build_operations }

=attr operations

ArrayRef of diff operation objects. Built lazily. Each object must respond to
C<as_sql> and C<summary>.

=cut

sub _build_operations {
  my ($self) = @_;
  die ref($self) . '::_build_operations not implemented';
}

=method has_changes

    if ($diff->has_changes) { ... }

Returns true if there is at least one diff operation.

=cut

sub has_changes {
  my ($self) = @_;
  return scalar @{ $self->operations } > 0;
}

=method as_sql

    my $sql = $diff->as_sql;

Returns all diff operations concatenated as a SQL migration script.

=cut

sub as_sql {
  my ($self) = @_;
  return join "\n", map { $_->as_sql } @{ $self->operations };
}

=method summary

    my $text = $diff->summary;

Returns a human-readable summary of all diff operations.

=cut

sub summary {
  my ($self) = @_;
  return join "\n", map { $_->summary } @{ $self->operations };
}

1;
