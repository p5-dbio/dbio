package DBIO::Storage::Async;
# ABSTRACT: Base class for async storage implementations

use strict;
use warnings;
use base 'DBIO::Storage';

use Carp 'croak';
use namespace::clean;

=head1 DESCRIPTION

Abstract base class for async DBIO storage drivers. Extends
L<DBIO::Storage> with async-specific infrastructure: connection
pooling, transaction pinning, and Future-based query execution.

Concrete implementations live in separate distributions:

=over 4

=item * L<DBIO::EV::Pg::Storage> — uses L<EV::Pg> (libpq, no DBI)

=item * L<Net::Async::DBIO::Storage> — uses L<IO::Async>

=item * L<Mojo::DBIO::Storage> — uses L<Mojo::IOLoop>

=back

=head1 SYNOPSIS

  # Users don't instantiate this directly — use a concrete driver:
  my $schema = MyApp::Schema->connect(
      'DBIO::EV::Pg',
      { host => 'localhost', dbname => 'myapp', pool_size => 10 },
  );

  # Async queries return Futures
  $schema->resultset('Artist')->all_async->then(sub {
      my @artists = @_;
      say $_->name for @artists;
  });

=cut

=method future_class

Must be overridden by subclasses to return the event-loop-specific
Future class (e.g. C<'Future'> for L<Future.pm|Future>).

=cut

sub future_class {
  croak 'Subclass must override future_class';
}

=method pool

Returns the connection pool object. Must be overridden by subclasses.

=cut

sub pool {
  croak 'Subclass must override pool';
}

=method select_async

  my $future = $storage->select_async($source, $select, $where, $attrs);

Must be overridden by subclasses with a non-blocking implementation
that returns a Future.

=cut

sub select_async { croak 'Subclass must override select_async' }

=method select_single_async

Must be overridden by subclasses.

=cut

sub select_single_async { croak 'Subclass must override select_single_async' }

=method insert_async

Must be overridden by subclasses.

=cut

sub insert_async { croak 'Subclass must override insert_async' }

=method update_async

Must be overridden by subclasses.

=cut

sub update_async { croak 'Subclass must override update_async' }

=method delete_async

Must be overridden by subclasses.

=cut

sub delete_async { croak 'Subclass must override delete_async' }

=method txn_do_async

  my $future = $storage->txn_do_async(sub { ... });

Acquires a connection from the pool, issues BEGIN, executes the
coderef, and issues COMMIT on success or ROLLBACK on failure.
The coderef receives a transaction-bound storage. Must be overridden.

=cut

sub txn_do_async { croak 'Subclass must override txn_do_async' }

=method pipeline

  my $future = $storage->pipeline(sub {
      my $storage = shift;
      # ... batch multiple queries ...
  });

Execute multiple queries in pipeline mode for reduced round-trips.
Optional — not all async drivers support this. Default croaks.

=cut

sub pipeline { croak 'Pipeline mode not supported by this storage driver' }

=method listen

  $storage->listen($channel, sub { my ($channel, $payload, $pid) = @_; });

Subscribe to database notifications (e.g. PostgreSQL LISTEN/NOTIFY).
Optional — not all databases support this. Default croaks.

=cut

sub listen { croak 'LISTEN/NOTIFY not supported by this storage driver' }

=method unlisten

  $storage->unlisten($channel);

Unsubscribe from a notification channel.

=cut

sub unlisten { croak 'LISTEN/NOTIFY not supported by this storage driver' }

1;
