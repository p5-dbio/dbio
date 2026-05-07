# ABSTRACT: Connection routing and credential lifecycle for DBIO
package DBIO::AccessBroker;

use strict;
use warnings;
use Carp qw(croak);
use Scalar::Util qw(blessed);
use namespace::clean;

# Storage-agnostic: works with both Storage::DBI and Storage::Async.
# The primary interface is connect_info_for_storage($storage, $mode), which
# returns storage-native connection parameters. Legacy connect_info_for($mode)
# remains available for DBI-shaped broker subclasses.
#
# Subclasses must implement:
#   connect_info_for_storage($storage, $mode) — returns storage-native
#                                               connect info for 'read' or 'write'
#   connect_info_for($mode) — legacy DBI-shaped connect info
#   needs_refresh()         — returns true if credentials need rotation
#   refresh()               — perform credential rotation

use Class::Accessor::Grouped;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors('simple' => qw(
  _storage
));

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  return $self;
}

# Set by Storage when broker is attached
sub set_storage {
  my ($self, $storage) = @_;
  $self->_storage($storage);
}

# Legacy DBI-shaped interface retained for built-in brokers and compatibility.
sub connect_info_for {
  croak ref($_[0]) . " must implement connect_info_for()";
}

# Primary storage-aware interface. Built-in brokers can often derive
# storage-native info from the legacy DBI-shaped form, so we provide that
# bridge here.
sub connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  $mode //= 'write';
  # Subclasses with storage-native formats override this.
  # Default: delegate to connect_info_for (DBI-shaped).
  return $self->connect_info_for($mode);
}

# Do credentials need rotation?
sub needs_refresh { 0 }

# Perform credential rotation
sub refresh { }

# Does this broker route reads and writes differently?
sub has_read_write_routing { 0 }

# Does this broker rotate credentials over time?
sub has_rotating_credentials { 0 }

# Can transactions safely run through this broker without an explicit override?
sub is_transaction_safe {
  my $self = shift;
  return $self->has_read_write_routing || $self->has_rotating_credentials ? 0 : 1;
}

# Check refresh and return connect info — legacy convenience for DBI-shaped
# callers or brokers already attached to a storage.
sub current_connect_info_for {
  my ($self, $mode) = @_;
  $mode //= 'write';
  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $self->_storage
    ? $self->connect_info_for_storage($self->_storage, $mode)
    : $self->connect_info_for($mode);
}

# Check refresh and return storage-native connect info.
sub current_connect_info_for_storage {
  my ($self, $storage, $mode) = @_;
  $mode //= 'write';
  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $self->connect_info_for_storage($storage, $mode);
}

1;

=head1 NAME

DBIO::AccessBroker - Connection routing and credential lifecycle for DBIO

=head1 SYNOPSIS

    # Static — same as traditional connect, one DSN
    use DBIO::AccessBroker::Static;
    my $broker = DBIO::AccessBroker::Static->new(
        dsn => 'dbi:Pg:dbname=myapp',
        username => 'app', password => 'secret',
    );
    # Storage gets storage-native connect info
    my $info = $broker->current_connect_info_for_storage($schema->storage, 'write');

    # ReadWrite — read replicas + write primary
    use DBIO::AccessBroker::ReadWrite;
    my $broker = DBIO::AccessBroker::ReadWrite->new(
        write => { dsn => 'dbi:Pg:host=primary', username => 'app', password => 'pw' },
        read  => [
            { dsn => 'dbi:Pg:host=replica1', username => 'ro', password => 'pw' },
            { dsn => 'dbi:Pg:host=replica2', username => 'ro', password => 'pw' },
        ],
    );
    $broker->connect_info_for('read');   # legacy DBI-shaped connect info
    $broker->connect_info_for('write');  # always returns primary

    # Vault — rotating credentials from OpenBao/Vault
    use DBIO::AccessBroker::Vault;
    my $broker = DBIO::AccessBroker::Vault->new(
        vault     => WWW::OpenBao->new(endpoint => 'http://vault:8200', token => $token),
        dsn       => 'dbi:Pg:dbname=myapp;host=db',
        cred_path => 'database/creds/myapp',
        ttl       => 3600,         # credentials valid for 1 hour
        refresh_margin => 900,     # refresh 15 min before expiry
    );
    # DBIO can now connect directly with a broker
    my $schema = MyApp::Schema->connect($broker);

=head1 DESCRIPTION

AccessBroker manages how DBIO connects to databases. It is
B<storage-agnostic> — it returns connection parameters, not handles.
This means it works with both C<Storage::DBI> (sync) and
C<Storage::Async> (async/Future-based). It handles:

=over 4

=item * B<Credential lifecycle> — fetching, rotating, and caching database credentials

=item * B<Connection routing> — directing reads to replicas and writes to primary

=back

=head1 TRANSACTION SAFETY

Transactions and broker-level routing/credential rotation are not equivalent
concepts.

DBIO therefore distinguishes between:

=over 4

=item * C<has_read_write_routing()> — reads and writes may land on different endpoints

=item * C<has_rotating_credentials()> — new connections may need refreshed credentials

=item * C<is_transaction_safe()> — DBIO may start a transaction through this broker without an explicit override

=back

The default implementation treats brokers as transaction-safe only when they do
neither routing nor credential rotation.

This means:

=over 4

=item * L<DBIO::AccessBroker::Static> is transaction-safe

=item * L<DBIO::AccessBroker::ReadWrite> is not transaction-safe by default

=item * L<DBIO::AccessBroker::Vault> is not transaction-safe by default

=back

Starting a transaction through a broker marked as unsafe will throw by default.
If you intentionally want to allow this, set
C<DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS=1>. DBIO will then proceed, but emit a
warning on transaction start.

=head1 SUBCLASSING

Implement these methods:

=over 4

=item C<connect_info_for_storage($storage, $mode)> — Return storage-native connect info for 'read' or 'write'

=item C<connect_info_for($mode)> — Optional legacy DBI-shaped connect info

=item C<needs_refresh()> — Return true if credentials should be rotated

=item C<refresh()> — Perform credential rotation

=item C<has_read_write_routing()> — Return true if the broker routes reads and writes differently

=item C<has_rotating_credentials()> — Return true if credentials rotate across connections

=item C<is_transaction_safe()> — Return true if DBIO may open transactions through this broker

=back

=cut
