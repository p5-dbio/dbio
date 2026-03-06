package DBIO::SQLMaker;
# ABSTRACT: An SQL::Abstract-based SQL maker class

use strict;
use warnings;

use base qw(
  DBIO::SQLMaker::ClassicExtensions
  SQL::Abstract
);

# NOTE THE LACK OF mro SPECIFICATION
# This is deliberate to ensure things will continue to work
# with ( usually ) untagged custom darkpan subclasses

1;

__END__

=head1 DESCRIPTION

This module serves as a mere "nexus class" providing
L<SQL::Abstract>-based SQL generation functionality to L<DBIO> itself, and
to a number of database-engine-specific subclasses. This indirection is
explicitly maintained in order to allow swapping out the core of SQL
generation within DBIO on per-C<$schema> basis without major architectural
changes. It is guaranteed by design and tests that this fast-switching
will continue being maintained indefinitely.

=head2 Implementation switching

See L<DBIO::Storage::DBI/connect_call_rebase_sqlmaker>

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIO resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIO) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.
