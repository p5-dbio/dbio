# ABSTRACT: Read replica pool with round-robin
package DBIO::AccessBroker::ReadWrite;

use strict;
use warnings;
use Carp qw(croak);
use DBI;
use base 'DBIO::AccessBroker';

__PACKAGE__->mk_group_accessors('simple' => qw(
  _write_info _read_infos _read_index _read_handles
));

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);

  my $write = $args{write} // croak "ReadWrite broker requires 'write'";
  my $read  = $args{read}  // croak "ReadWrite broker requires 'read'";
  $read = [$read] if ref $read eq 'HASH';

  $self->_write_info(_normalize_info($write));
  $self->_read_infos([map { _normalize_info($_) } @$read]);
  $self->_read_index(0);
  $self->_read_handles([]);

  return $self;
}

sub _normalize_info {
  my ($info) = @_;
  return [$info->{dsn}, $info->{username} // '', $info->{password} // '', $info->{dbi_attrs} // {}];
}

sub connect_info_for {
  my ($self, $mode) = @_;
  return $self->_write_info if $mode eq 'write';

  # Round-robin through read replicas
  my $infos = $self->_read_infos;
  my $idx = $self->_read_index;
  $self->_read_index(($idx + 1) % scalar @$infos);
  return $infos->[$idx];
}

sub dbh_for {
  my ($self, $mode) = @_;
  $mode //= 'write';

  # Write: always same handle via parent
  return $self->SUPER::dbh_for('write') if $mode eq 'write';

  # Read: round-robin, but cache per-replica
  my $infos = $self->_read_infos;
  my $idx = $self->_read_index;
  my $handles = $self->_read_handles;

  # Check cached handle for this replica
  if ($handles->[$idx] && eval { $handles->[$idx]->ping }) {
    my $dbh = $handles->[$idx];
    $self->_read_index(($idx + 1) % scalar @$infos);
    return $dbh;
  }

  # Connect this replica
  my $info = $infos->[$idx];
  my ($dsn, $user, $pass, $attrs) = @$info;
  $attrs //= {};
  $attrs->{AutoCommit} //= 1;
  $attrs->{RaiseError} //= 1;

  my $dbh = DBI->connect($dsn, $user, $pass, $attrs)
    or croak "ReadWrite connect failed for read[$idx]: " . DBI->errstr;

  $handles->[$idx] = $dbh;
  $self->_read_handles($handles);
  $self->_read_index(($idx + 1) % scalar @$infos);
  return $dbh;
}

sub disconnect {
  my ($self) = @_;
  $self->SUPER::disconnect;
  for my $dbh (@{ $self->_read_handles // [] }) {
    $dbh->disconnect if $dbh && $dbh->{Active};
  }
  $self->_read_handles([]);
}

1;