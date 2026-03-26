# ABSTRACT: Connection routing and credential lifecycle for DBIO
package DBIO::AccessBroker;

use strict;
use warnings;
use Carp qw(croak);
use DBI;

# Abstract interface for connection routing and credential lifecycle.
#
# Subclasses must implement:
#   connect_info_for($mode) — returns [$dsn, $user, $pass, \%attrs] for 'read' or 'write'
#   needs_refresh()         — returns true if credentials need rotation
#   refresh()               — perform credential rotation
#
# The optional dbh_for($mode) method manages DBI handles.
# Default implementation creates/caches handles per mode.

use Class::Accessor::Grouped;
use base 'Class::Accessor::Grouped';

__PACKAGE__->mk_group_accessors('simple' => qw(
  _handles
  _storage
));

sub new {
  my ($class, %args) = @_;
  my $self = bless {}, $class;
  $self->_handles({});
  return $self;
}

# Set by Storage::DBI when broker is attached
sub set_storage {
  my ($self, $storage) = @_;
  $self->_storage($storage);
}

# Get a DBI handle for the given mode ('read' or 'write')
# Caches handles per mode. Reconnects if needed.
sub dbh_for {
  my ($self, $mode) = @_;
  $mode //= 'write';

  # Check if refresh is needed
  if ($self->needs_refresh) {
    $self->refresh;
    # Clear cached handles — new credentials
    $self->_handles({});
  }

  my $handles = $self->_handles;
  my $dbh = $handles->{$mode};

  # Return cached if still alive
  if ($dbh && eval { $dbh->ping }) {
    return $dbh;
  }

  # Connect with mode-specific info
  my $info = $self->connect_info_for($mode);
  croak "connect_info_for('$mode') must return an arrayref" unless ref $info eq 'ARRAY';

  my ($dsn, $user, $pass, $attrs) = @$info;
  $attrs //= {};
  $attrs->{AutoCommit} //= 1;
  $attrs->{RaiseError} //= 1;

  $dbh = DBI->connect($dsn, $user, $pass, $attrs)
    or croak "AccessBroker connect failed for '$mode': " . DBI->errstr;

  $handles->{$mode} = $dbh;
  $self->_handles($handles);
  return $dbh;
}

# Abstract: return [$dsn, $user, $pass, \%attrs] for a mode
sub connect_info_for {
  croak ref($_[0]) . " must implement connect_info_for()";
}

# Abstract: do credentials need rotation?
sub needs_refresh { 0 }

# Abstract: rotate credentials (clear cached handles after)
sub refresh { }

# Disconnect all handles
sub disconnect {
  my ($self) = @_;
  my $handles = $self->_handles;
  for my $dbh (values %$handles) {
    $dbh->disconnect if $dbh && $dbh->{Active};
  }
  $self->_handles({});
}

1;

=head1 NAME

DBIO::AccessBroker - Connection routing and credential lifecycle for DBIO

=head1 SYNOPSIS

    # Static — same as traditional connect, one DSN
    use DBIO::AccessBroker::Static;
    my $schema = MyApp::Schema->connect(sub {
        DBIO::AccessBroker::Static->new(
            dsn => 'dbi:Pg:dbname=myapp',
            username => 'app', password => 'secret',
        )->dbh_for('write');
    });

    # ReadWrite — read replicas + write primary
    use DBIO::AccessBroker::ReadWrite;
    my $broker = DBIO::AccessBroker::ReadWrite->new(
        write => { dsn => 'dbi:Pg:host=primary', username => 'app', password => 'pw' },
        read  => [
            { dsn => 'dbi:Pg:host=replica1', username => 'ro', password => 'pw' },
            { dsn => 'dbi:Pg:host=replica2', username => 'ro', password => 'pw' },
        ],
    );

    # Vault — rotating credentials from OpenBao/Vault
    use DBIO::AccessBroker::Vault;
    my $broker = DBIO::AccessBroker::Vault->new(
        vault     => WWW::OpenBao->new(endpoint => 'http://vault:8200', token => $token),
        dsn       => 'dbi:Pg:dbname=myapp;host=db',
        cred_path => 'database/creds/myapp',
        ttl       => 3600,         # credentials valid for 1 hour
        refresh_margin => 900,     # refresh 15 min before expiry
    );

=head1 DESCRIPTION

AccessBroker manages how DBIO connects to databases. It handles:

=over 4

=item * B<Credential lifecycle> — fetching, rotating, and caching database credentials

=item * B<Connection routing> — directing reads to replicas and writes to primary

=item * B<Connection pooling> — managing multiple DBI handles efficiently

=item * B<Health checking> — detecting dead connections and reconnecting

=back

=head1 SUBCLASSING

Implement these methods:

=over 4

=item C<connect_info_for($mode)> — Return C<[$dsn, $user, $pass, \%attrs]> for 'read' or 'write'

=item C<needs_refresh()> — Return true if credentials should be rotated

=item C<refresh()> — Perform credential rotation

=back

=cut