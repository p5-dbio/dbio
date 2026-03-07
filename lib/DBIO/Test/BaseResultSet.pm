package DBIO::Test::BaseResultSet;
# ABSTRACT: Base class for DBIO test ResultSet classes

use strict;
use warnings;

use base 'DBIO::ResultSet';

=method all_hri

  my $rows = $rs->all_hri;

Convenience method that returns all rows as an arrayref of hashrefs
via L<DBIO::ResultClass::HashRefInflator>.

=cut

sub all_hri {
  return [ shift->search({}, { result_class => 'DBIO::ResultClass::HashRefInflator' })->all ];
}

1;
