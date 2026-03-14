package DBIO::Replicated;
# ABSTRACT: Replicated storage support for DBIO

use strict;
use warnings;

use base 'DBIO';

=head1 SYNOPSIS

  package MyApp::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DBIO::Replicated');

  my $schema = __PACKAGE__->connect($dsn, $user, $pass, {
    balancer_type => 'DBIO::Replicated::Balancer::First',
  });

=head1 DESCRIPTION

L<DBIO::Replicated> is the DBIO core component for replicated storage
setups. It configures the schema to use L<DBIO::Replicated::Storage>,
which then coordinates a master backend plus optional replicant
backends.

For shared test suites, L<DBIO::Test> can wrap a requested backend
storage in replicated mode with:

  my $schema = DBIO::Test->init_schema(
    replicated   => 1,
    storage_type => 'DBIO::MySQL::Storage',
  );

=head1 METHODS

=method connection

Overrides L<DBIO/connection> to force C<+DBIO::Replicated::Storage> as
C<storage_type>.

=cut

sub connection {
  my ($self, @info) = @_;
  $self->storage_type('+DBIO::Replicated::Storage');
  return $self->next::method(@info);
}

1;
