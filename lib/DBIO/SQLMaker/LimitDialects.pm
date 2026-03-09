# because of how loose dep specs are, we need to keep squatting
# on the CPAN face - FOREVER.
package DBIO::SQLMaker::LimitDialects;
# ABSTRACT: SQL::Abstract::Limit-like functionality in DBIO::SQLMaker

use warnings;
use strict;

##
## Compat in case someone is using these in the wild...
##

my $sigh = sub {
  require DBIO::Util;
  require DBIO::SQLMaker;

  my( $meth ) = (caller(1))[3] =~ /([^:]+)$/;

  DBIO::Util::emit_loud_diag(
    skip_frames => 1,
    msg => "The $meth() constant is now provided by DBIO::SQLMaker::ClassicExtensions: please adjust your code"
  );

  DBIO::SQLMaker::ClassicExtensions->$meth;
};

=method __rows_bindtype

Compatibility shim forwarding to C<DBIO::SQLMaker::ClassicExtensions>.

=cut

sub __rows_bindtype { $sigh->() }

=method __offset_bindtype

Compatibility shim forwarding to C<DBIO::SQLMaker::ClassicExtensions>.

=cut

sub __offset_bindtype { $sigh->() }

=method __total_bindtype

Compatibility shim forwarding to C<DBIO::SQLMaker::ClassicExtensions>.

=cut

sub __total_bindtype { $sigh->() }

1;

__END__

=head1 DESCRIPTION

DBIO's SQLMaker stack replicates and surpasses all of the functionality
originally found in L<SQL::Abstract::Limit>. While simple limits would
work as-is, the more complex dialects that require e.g. subqueries could
not be reliably implemented without taking full advantage of the metadata
locked within L<DBIO::ResultSource> classes. After reimplementation
of close to 80% of the L<SQL::Abstract::Limit> functionality it was deemed
more practical to simply make an independent DBIO-specific
limit-dialect provider.

=head1 SQL LIMIT DIALECTS

Note that the actual implementations listed below never use C<*> literally.
Instead proper re-aliasing of selectors and order criteria is done, so that
the limit dialect are safe to use on joined resultsets with clashing column
names.

Currently the provided dialects are:

=head2 LimitOffset

 SELECT ... LIMIT $limit OFFSET $offset

Supported by B<PostgreSQL> and B<SQLite>

=head2 LimitXY

 SELECT ... LIMIT $offset, $limit

Supported by B<MySQL> and any L<SQL::Statement> based DBD

=head2 RowNumberOver

 SELECT * FROM (
  SELECT *, ROW_NUMBER() OVER( ORDER BY ... ) AS RNO__ROW__INDEX FROM (
   SELECT ...
  )
 ) WHERE RNO__ROW__INDEX BETWEEN ($offset+1) AND ($limit+$offset)


ANSI standard Limit/Offset implementation. Supported by B<DB2> and
B<< MSSQL >= 2005 >>.

=head2 SkipFirst

 SELECT SKIP $offset FIRST $limit * FROM ...

Supported by B<Informix>, almost like LimitOffset. According to
L<SQL::Abstract::Limit> C<... SKIP $offset LIMIT $limit ...> is also supported.

=head2 FirstSkip

 SELECT FIRST $limit SKIP $offset * FROM ...

Supported by B<Firebird/Interbase>, reverse of SkipFirst. According to
L<SQL::Abstract::Limit> C<... ROWS $limit TO $offset ...> is also supported.

=head2 RowNum

Depending on the resultset attributes one of:

 SELECT * FROM (
  SELECT *, ROWNUM AS rownum__index FROM (
   SELECT ...
  ) WHERE ROWNUM <= ($limit+$offset)
 ) WHERE rownum__index >= ($offset+1)

or

 SELECT * FROM (
  SELECT *, ROWNUM AS rownum__index FROM (
    SELECT ...
  )
 ) WHERE rownum__index BETWEEN ($offset+1) AND ($limit+$offset)

or

 SELECT * FROM (
    SELECT ...
  ) WHERE ROWNUM <= ($limit+1)

Supported by B<Oracle>.

=head2 Top

 SELECT * FROM

 SELECT TOP $limit FROM (
  SELECT TOP $limit FROM (
   SELECT TOP ($limit+$offset) ...
  ) ORDER BY $reversed_original_order
 ) ORDER BY $original_order

Unreliable Top-based implementation, supported by B<< MSSQL < 2005 >>.

=head3 CAVEAT

Due to its implementation, this limit dialect returns B<incorrect results>
when $limit+$offset > total amount of rows in the resultset.

=head2 FetchFirst

 SELECT * FROM
 (
 SELECT * FROM (
  SELECT * FROM (
   SELECT * FROM ...
  ) ORDER BY $reversed_original_order
    FETCH FIRST $limit ROWS ONLY
 ) ORDER BY $original_order
   FETCH FIRST $limit ROWS ONLY
 )

Unreliable FetchFirst-based implementation, supported by B<< IBM DB2 <= V5R3 >>.

=head3 CAVEAT

Due to its implementation, this limit dialect returns B<incorrect results>
when $limit+$offset > total amount of rows in the resultset.

=head2 GenericSubQ

 SELECT * FROM (
  SELECT ...
 )
 WHERE (
  SELECT COUNT(*) FROM $original_table cnt WHERE cnt.id < $original_table.id
 ) BETWEEN $offset AND ($offset+$rows-1)

This is the most evil limit "dialect" (more of a hack) for I<really> stupid
databases. It works by ordering the set by some unique column, and calculating
the amount of rows that have a less-er value (thus emulating a L</RowNum>-like
index). Of course this implies the set can only be ordered by a single unique
column.

Also note that this technique can be and often is B<excruciatingly slow>. You
may have much better luck using L<DBIO::ResultSet/software_limit>
instead.

Currently used by B<Sybase ASE>, due to lack of any other option.

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
