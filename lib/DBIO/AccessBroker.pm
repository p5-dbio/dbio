# ABSTRACT: Connection routing and credential lifecycle for DBIO
package DBIO::AccessBroker;

use strict;
use warnings;
use Carp qw(croak);

# Storage-agnostic: works with both Storage::DBI and Storage::Async.
# The primary interface is connect_info_for($mode) which returns
# connection parameters. Each Storage type decides HOW to connect.
#
# Subclasses must implement:
#   connect_info_for($mode) — returns [$dsn, $user, $pass, \%attrs] for 'read' or 'write'
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

# Primary interface: return [$dsn, $user, $pass, \%attrs] for a mode
# This is what Storage::DBI and Storage::Async both consume.
sub connect_info_for {
  croak ref($_[0]) . " must implement connect_info_for()";
}

# Do credentials need rotation?
sub needs_refresh { 0 }

# Perform credential rotation
sub refresh { }

# Check refresh and return connect info — convenience for Storage consumers
sub current_connect_info_for {
  my ($self, $mode) = @_;
  $mode //= 'write';
  if ($self->needs_refresh) {
    $self->refresh;
  }
  return $self->connect_info_for($mode);
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
    # Storage gets connect info — works with DBI and Async
    my $info = $broker->current_connect_info_for('write');
    # → ['dbi:Pg:dbname=myapp', 'app', 'secret', {}]

    # ReadWrite — read replicas + write primary
    use DBIO::AccessBroker::ReadWrite;
    my $broker = DBIO::AccessBroker::ReadWrite->new(
        write => { dsn => 'dbi:Pg:host=primary', username => 'app', password => 'pw' },
        read  => [
            { dsn => 'dbi:Pg:host=replica1', username => 'ro', password => 'pw' },
            { dsn => 'dbi:Pg:host=replica2', username => 'ro', password => 'pw' },
        ],
    );
    $broker->connect_info_for('read');   # round-robins through replicas
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
    # current_connect_info_for auto-refreshes when TTL approaches
    $broker->current_connect_info_for('write');  # fresh creds every time

    # Integration with DBIO (via coderef-connect, works today)
    my $schema = MyApp::Schema->connect(sub {
        my $info = $broker->current_connect_info_for('write');
        DBI->connect(@$info);
    });

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

=item C<connect_info_for($mode)> — Return C<[$dsn, $user, $pass, \%attrs]> for 'read' or 'write'

=item C<needs_refresh()> — Return true if credentials should be rotated

=item C<refresh()> — Perform credential rotation

=back

=cut