# Namespace squat — kept to prevent conflicts with the old
# DBIx::Class::SQLMaker::LimitDialects CPAN distribution.
package DBIO::SQLMaker::LimitDialects;
# ABSTRACT: Reserved namespace (limit logic lives in driver SQLMakers)

use warnings;
use strict;

1;

__END__

=head1 DESCRIPTION

This module exists only to reserve the CPAN namespace. In DBIO, limit/offset
handling is provided by each database driver's SQLMaker class via the
L<apply_limit|DBIO::SQLMaker::ClassicExtensions/apply_limit> method.

The default implementation (C<LIMIT ? OFFSET ?>) lives in
L<DBIO::SQLMaker::ClassicExtensions>. Database-specific dialects are
provided by driver distributions:

=over 4

=item * L<DBIO::MySQL::SQLMaker> — C<LIMIT ?, ?>

=item * PostgreSQL, SQLite — use the default C<LIMIT ? OFFSET ?>

=back

=cut
