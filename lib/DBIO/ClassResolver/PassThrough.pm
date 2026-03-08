package DBIO::ClassResolver::PassThrough;
# ABSTRACT: Class resolver that returns names unchanged

use strict;
use warnings;

=head1 DESCRIPTION

Minimal class resolver returning the supplied class name unchanged.

=head1 METHODS

=method class

Return the class name argument unchanged.

=cut

sub class {
  shift;
  return shift;
}

1;
