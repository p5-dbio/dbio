package DBIO::Future;
# ABSTRACT: Future interface contract for async DBIO operations

use strict;
use warnings;

use Carp 'croak';

=head1 DESCRIPTION

Defines the interface contract that all DBIO-compatible Future objects
must implement. This is B<not> a base class — async distributions bring
their own Future implementation (L<Future>, L<Mojo::Promise>, etc.).

The interface is intentionally minimal to maximize compatibility across
event loop ecosystems.

=head1 REQUIRED METHODS

Any object returned by DBIO async methods must support these methods:

=over 4

=item then

  $future->then(sub { my @result = @_; ... });

Success callback. Called with the resolved values when the Future
completes successfully. Must return a new Future.

=item catch

  $future->catch(sub { my $error = shift; ... });

Error callback. Called with the error when the Future fails.
Must return a new Future.

=item get

  my @result = $future->get;

Block until the Future is resolved and return the result.
Dies if the Future failed.

=item is_ready

  if ($future->is_ready) { ... }

Returns true if the Future has been resolved (either success or failure).

=item is_failed

  if ($future->is_failed) { ... }

Returns true if the Future was resolved with an error.

=back

=method validate

  DBIO::Future->validate($obj);

Verifies that C<$obj> implements the required Future interface.
Croaks if any required method is missing.

=cut

sub validate {
  my ($class, $obj) = @_;
  for (qw(then catch get is_ready is_failed)) {
    croak "$obj does not implement $_" unless $obj->can($_);
  }
  return 1;
}

1;
