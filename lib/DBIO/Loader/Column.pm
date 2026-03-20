package DBIO::Loader::Column;
# ABSTRACT: Column metadata object

use strict;
use warnings;
use base 'Class::Accessor::Grouped';
use mro 'c3';
use Carp::Clan qw/^DBIO/;
use Scalar::Util 'weaken';
use namespace::clean;

=head1 NAME

DBIO::Loader::Column - Class for Columns in
L<DBIO::Loader>

=head1 DESCRIPTION

Used for representing columns in
L<DBIO::Loader::Base/col_accessor_map>.

Stringifies to L</name>, and arrayrefifies to the
L<name_parts|DBIO::Loader::Table/name_parts> of
L</table> plus L</name>.

=cut

__PACKAGE__->mk_group_accessors(simple => qw/
    table
    name
/);

use overload
    '""' => sub { $_[0]->name },
    '@{}' => sub { [ @{$_[0]->table->name_parts}, $_[0]->name ] },
    fallback => 1;

=head1 METHODS

=head2 new

The constructor. Takes L</table> and L</name> key-value parameters.

=cut

sub new {
    my $class = shift;

    my $self = { @_ };
    croak "table is required" unless ref $self->{table};

    weaken $self->{table};

    return bless $self, $class;
}

=head2 table

The L</DBIO::Loader::Table> object this column belongs to.
Required parameter for L</new>

=head2 name

The name of the column. Required parameter for L</new>.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
