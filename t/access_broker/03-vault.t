# ABSTRACT: Vault broker test
use strict;
use warnings;
use Test::More;

# Mock vault — no HTTP needed
{
  package MockVault;
  sub new { bless { calls => 0, @_[1..$#_] }, $_[0] }
  sub read_secret {
    my ($self, $path) = @_;
    $self->{calls}++;
    return {
      username => "dynamic-user-" . $self->{calls},
      password => "dynamic-pass-" . $self->{calls},
    };
  }
}

use_ok('DBIO::AccessBroker::Vault');

my $vault = MockVault->new;
my $broker = DBIO::AccessBroker::Vault->new(
  vault     => $vault,
  dsn       => 'dbi:SQLite:dbname=:memory:',
  cred_path => 'database/creds/myapp',
  ttl       => 3600,
);

ok $broker, 'Vault broker constructor';
isa_ok $broker, 'DBIO::AccessBroker';

# First call gets credentials from vault
my $info = $broker->connect_info_for('write');
is $info->[1], 'dynamic-user-1', 'first credentials from vault';

# needs_refresh is false (just fetched)
ok !$broker->needs_refresh, 'no refresh needed after fetch';

# At exactly refresh_margin before expiry: still not ready
$broker->_expires_at(time() + $broker->refresh_margin + 1);
ok !$broker->needs_refresh, 'no refresh before margin';

# Simulate TTL expiry
$broker->_expires_at(time() - 1);
ok $broker->needs_refresh, 'needs refresh after TTL expiry';

# Refresh gets new credentials
$broker->refresh;
my $info2 = $broker->connect_info_for('write');
is $info2->[1], 'dynamic-user-2', 'refreshed credentials from vault';

done_testing;