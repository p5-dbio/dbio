package DBIO::Storage::DBI::Replicated::Balancer::First;
# ABSTRACT: Just get the First Balancer

use Moose;
with 'DBIO::Storage::DBI::Replicated::Balancer';
use namespace::clean -except => 'meta';

=head1 SYNOPSIS

This class is used internally by L<DBIO::Storage::DBI::Replicated>.  You
shouldn't need to create instances of this class.

=head1 DESCRIPTION

Given a pool (L<DBIO::Storage::DBI::Replicated::Pool>) of replicated
database's (L<DBIO::Storage::DBI::Replicated::Replicant>), defines a
method by which query load can be spread out across each replicant in the pool.

This Balancer just gets whichever is the first replicant in the pool.

=head1 ATTRIBUTES

This class defines the following attributes.

=head1 METHODS

This class defines the following methods.

=head2 next_storage

Just get the first storage.  Probably only good when you have one replicant.

=cut

sub next_storage {
  return  (shift->pool->active_replicants)[0];
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

__PACKAGE__->meta->make_immutable;

1;
