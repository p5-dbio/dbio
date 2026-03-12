package DBIO::Cursor;
# ABSTRACT: Abstract object representing a query cursor on a resultset.

use strict;
use warnings;

use base qw/DBIO/;

=head1 SYNOPSIS

  my $cursor = $schema->resultset('CD')->cursor();

  # raw values off the database handle in resultset columns/select order
  my @next_cd_column_values = $cursor->next;

  # list of all raw values as arrayrefs
  my @all_cds_column_values = $cursor->all;

=head1 DESCRIPTION

A Cursor represents a query cursor on a L<DBIO::ResultSet> object. It
allows for traversing the result set with L</next>, retrieving all results with
L</all> and resetting the cursor with L</reset>.

Usually, you would use the cursor methods built into L<DBIO::ResultSet>
to traverse it. See L<DBIO::ResultSet/next>,
L<DBIO::ResultSet/reset> and L<DBIO::ResultSet/all> for more
information.

=head1 METHODS

=method new

Virtual method. Returns a new L<DBIO::Cursor> object.

=cut

sub new {
  die "Virtual method!";
}

=method next

Virtual method. Advances the cursor to the next row. Returns an array of
column values (the result of L<DBI/fetchrow_array> method).

=cut

sub next {
  die "Virtual method!";
}

=method reset

Virtual method. Resets the cursor to the beginning.

=cut

sub reset {
  die "Virtual method!";
}

=method all

Virtual method. Returns all rows in the L<DBIO::ResultSet>.

=cut

sub all {
  my ($self) = @_;
  $self->reset;
  my @all;
  while (my @row = $self->next) {
    push(@all, \@row);
  }
  $self->reset;
  return @all;
}


1;
