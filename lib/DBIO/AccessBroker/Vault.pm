# ABSTRACT: Credential rotation with TTL
package DBIO::AccessBroker::Vault;

use strict;
use warnings;
use Carp qw(croak);
use base 'DBIO::AccessBroker';

__PACKAGE__->mk_group_accessors('simple' => qw(
  vault dsn dbi_attrs cred_path ttl refresh_margin
  _current_username _current_password _expires_at
));

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);

  $self->vault($args{vault})           // croak "Vault broker requires 'vault'";
  $self->dsn($args{dsn})               // croak "Vault broker requires 'dsn'";
  $self->cred_path($args{cred_path})   // croak "Vault broker requires 'cred_path'";
  $self->ttl($args{ttl}                // 3600);
  $self->refresh_margin($args{refresh_margin} // 900);  # 15 min before expiry
  $self->dbi_attrs($args{dbi_attrs}    // {});
  $self->_expires_at(0);

  # Fetch initial credentials
  $self->_fetch_credentials;

  return $self;
}

sub _fetch_credentials {
  my ($self) = @_;
  my $creds = $self->vault->read_secret($self->cred_path);
  croak "Vault returned no credentials for " . $self->cred_path unless $creds;
  $self->_current_username($creds->{username});
  $self->_current_password($creds->{password});
  $self->_expires_at(time() + $self->ttl);
}

sub connect_info_for {
  my ($self, $mode) = @_;
  return [$self->dsn, $self->_current_username, $self->_current_password, $self->dbi_attrs];
}

sub needs_refresh {
  my ($self) = @_;
  return time() > ($self->_expires_at - $self->refresh_margin);
}

sub refresh {
  my ($self) = @_;
  $self->_fetch_credentials;
  # Clear cached handles so next dbh_for() reconnects with new creds
  $self->_handles({});
}

1;