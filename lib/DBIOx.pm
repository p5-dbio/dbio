package DBIOx;
# ABSTRACT: Bring your own database magic!

use strict;
use warnings;

1;

=head1 DESCRIPTION

The B<DBIOx> namespace is the conventional home for third-party extensions to
L<DBIO>. If you are building a module that extends or integrates with DBIO but
does not belong in the core distribution, publish it under C<DBIOx::>.

For custom storage drivers, publish under C<DBIOx::Storage::*>. For custom
components, publish under C<DBIOx::Component::*>. For ResultSet extensions,
publish under C<DBIOx::ResultSet::*>.

DBIO resolves configured component names against both C<DBIO::> and C<DBIOx::>
namespaces via L<DBIO::Componentised>.

=cut
