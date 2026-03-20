package DBIO::Loader::DBI::Writing;
# ABSTRACT: Guide for writing DBIO Loader driver classes
use strict;
use warnings;

our $VERSION = '0.07053';

# Empty. POD only.

=head1 NAME

DBIO::Loader::DBI::Writing - Loader subclass writing guide for DBI

=head1 SYNOPSIS

    # For a driver-specific Loader, use the DBIO::DriverName::Loader
    # naming convention:
    package DBIO::Foo::Loader;

    # THIS IS JUST A TEMPLATE TO GET YOU STARTED.

    use strict;
    use warnings;
    use base 'DBIO::Loader::DBI';
    use mro 'c3';

    sub _table_uniq_info {
        my ($self, $table) = @_;

        # ... get UNIQUE info for $table somehow
        # and return a data structure that looks like this:

        return [
             [ 'keyname' => [ 'colname' ] ],
             [ 'keyname2' => [ 'col1name', 'col2name' ] ],
             [ 'keyname3' => [ 'colname' ] ],
        ];

        # Where the "keyname"'s are just unique identifiers, such as the
        # name of the unique constraint, or the names of the columns involved
        # concatenated if you wish.
    }

    sub _table_comment {
        my ( $self, $table ) = @_;
        return 'Comment';
    }

    sub _column_comment {
        my ( $self, $table, $column_number ) = @_;
        return 'Col. comment';
    }

    1;

=head1 DETAILS

The only required method for new subclasses is C<_table_uniq_info>,
as there is not (yet) any standardized, DBD-agnostic way for obtaining
this information from DBI.

The base DBI Loader contains generic methods that *should* work for
everything else in theory, although in practice some DBDs need to
override one or more of the other methods.  The other methods one might
likely want to override are: C<_table_pk_info>, C<_table_fk_info>,
C<_tables_list> and C<_extra_column_info>.  For examples of
driver-specific implementations, see the Loader classes in the separate
DBIO driver distributions (e.g. L<DBIO::PostgreSQL::Loader> in
L<DBIO::PostgreSQL>, L<DBIO::MySQL::Loader> in L<DBIO::MySQL>,
L<DBIO::SQLite::Loader> in L<DBIO::SQLite>).

To import comments from the database you need to implement C<_table_comment>,
C<_column_comment>

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
