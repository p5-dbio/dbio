package DBIO::CDBICompat::Iterator;

use strict;
use warnings;


=head1 NAME

DBIO::CDBICompat::Iterator - Emulates the extra behaviors of the Class::DBI search iterator.

=head1 SYNOPSIS

See DBIO::CDBICompat for usage directions.

=head1 DESCRIPTION

Emulates the extra behaviors of the Class::DBI search iterator.

=head2 Differences from DBIO result set

The CDBI iterator returns true if there were any results, false otherwise.  The DBIC result set always returns true.

=cut


sub _init_result_source_instance {
  my $class = shift;

  my $table = $class->next::method(@_);
  $table->resultset_class("DBIO::CDBICompat::Iterator::ResultSet");

  return $table;
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

package # hide
  DBIO::CDBICompat::Iterator::ResultSet;

use strict;
use warnings;

use base qw(DBIO::ResultSet);

sub _bool {
    # Performance hack so internal checks whether the result set
    # exists won't do a SQL COUNT.
    return 1 if caller =~ /^DBIO::/;

    return $_[0]->count;
}

sub _construct_results {
  my $self = shift;

  my $rows = $self->next::method(@_);

  if (my $f = $self->_resolved_attrs->{record_filter}) {
    $_ = $f->($_) for @$rows;
  }

  return $rows;
}

1;
