package DBIO::Storage::Pool;
# ABSTRACT: Abstract connection pool interface for async storage

use strict;
use warnings;

use Carp 'croak';
use namespace::clean;

=head1 DESCRIPTION

Defines the interface contract for connection pools used by
L<DBIO::Storage::Async> drivers. This is an abstract base — concrete
implementations live in async driver distributions.

Sync storage (L<DBIO::Storage::DBI>) does not use a pool — it manages
a single connection directly. This interface is only relevant for async
storage drivers that need to multiplex queries across multiple
connections.

=head1 SYNOPSIS

  # Implemented by async distributions, e.g.:
  package DBIO::EV::Pg::Pool;
  use base 'DBIO::Storage::Pool';

  sub acquire { ... }   # return Future resolving to a connection
  sub release { ... }   # return connection to pool

=cut

=method acquire

  my $future = $pool->acquire;

Acquire a connection from the pool. Returns a Future that resolves
to a connection handle. If no connections are available, the Future
waits until one is released.

=cut

sub acquire { croak 'Subclass must override acquire' }

=method release

  $pool->release($connection);

Return a connection to the pool, making it available for other
queries.

=cut

sub release { croak 'Subclass must override release' }

=method acquire_txn

  my $future = $pool->acquire_txn;

Acquire a connection pinned for exclusive transaction use. The
connection will not be returned to the general pool until the
transaction completes (COMMIT or ROLLBACK).

=cut

sub acquire_txn { croak 'Subclass must override acquire_txn' }

=method size

  my $n = $pool->size;

Returns the total number of connections in the pool (active + idle).

=cut

sub size { croak 'Subclass must override size' }

=method available

  my $n = $pool->available;

Returns the number of idle connections ready for use.

=cut

sub available { croak 'Subclass must override available' }

=method max_size

  my $n = $pool->max_size;

Returns the configured maximum pool size.

=cut

sub max_size { croak 'Subclass must override max_size' }

1;
