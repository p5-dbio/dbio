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

  my $connect_info = $self->connect_info_for($mode);

  return $connect_info if blessed($storage) && $storage->isa('DBIO::Storage::DBI');

  if (blessed($storage) && $storage->isa('DBIO::PostgreSQL::Async::Storage')) {
    return [ $self->_pg_async_connect_info_from_dbi_info($connect_info), {} ];
  }

  croak sprintf(
    "%s can not derive connect info for storage %s",
    ref($self) || $self,
    (blessed($storage) ? ref($storage) : 'unknown'),
  );
}

# Do credentials need rotation?
sub needs_refresh { 0 }

# Perform credential rotation
sub refresh { }

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

sub _pg_async_connect_info_from_dbi_info {
  my ($self, $connect_info) = @_;

  my ($dsn, $user, $pass, $attrs) = @{ $connect_info || [] };
  my ($params) = ($dsn || '') =~ /^dbi:Pg:(.+)$/i;

  croak sprintf(
    "%s can not derive async PostgreSQL conninfo from DSN '%s'",
    ref($self) || $self,
    (defined $dsn ? $dsn : ''),
  ) unless defined $params;

  my %conninfo = map {
    my ($key, $value) = split /=/, $_, 2;
    $key => $value;
  } grep { length $_ } split /;/, $params;

  $conninfo{user} = $user if defined $user && length $user;
  $conninfo{password} = $pass if defined $pass && length $pass;
  $conninfo{pool_size} = $attrs->{pool_size}
    if ref($attrs) eq 'HASH' && exists $attrs->{pool_size};

  return \%conninfo;
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

=head1 SUBCLASSING

Implement these methods:

=over 4

=item C<connect_info_for_storage($storage, $mode)> — Return storage-native connect info for 'read' or 'write'

=item C<connect_info_for($mode)> — Optional legacy DBI-shaped connect info

=item C<needs_refresh()> — Return true if credentials should be rotated

=item C<refresh()> — Perform credential rotation

=back

=cut
