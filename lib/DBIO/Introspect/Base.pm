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

1;
