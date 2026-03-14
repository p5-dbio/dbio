package DBIO::Replicated::DebugProxy;
# ABSTRACT: Prefix trace output with replicated backend identity

use strict;
use warnings;

use Scalar::Util 'reftype';

sub new {
  my ($class, %args) = @_;
  return bless {
    backend => $args{backend},
    target  => $args{target},
  }, $class;
}

sub backend { $_[0]->{backend} }
sub target  { $_[0]->{target} }

sub callback { shift->target->callback(@_) }
sub debugfh  { shift->target->debugfh(@_) }
sub silence  { shift->target->silence(@_) }
sub print    { shift->target->print(@_) }
sub txn_begin    { shift->target->txn_begin(@_) }
sub txn_commit   { shift->target->txn_commit(@_) }
sub txn_rollback { shift->target->txn_rollback(@_) }
sub svp_begin    { shift->target->svp_begin(@_) }
sub svp_release  { shift->target->svp_release(@_) }
sub svp_rollback { shift->target->svp_rollback(@_) }

sub query_start {
  my ($self, $sql, @bind) = @_;
  return $self->target->query_start($self->_decorate_sql($sql), @bind);
}

sub query_end {
  my ($self, $sql, @bind) = @_;
  return $self->target->query_end($self->_decorate_sql($sql), @bind);
}

sub _decorate_sql {
  my ($self, $sql) = @_;

  my $dsn = eval { $self->backend->dsn };
  $dsn ||= eval { $self->backend->storage->_dbi_connect_info->[0] };

  my $kind = uc($self->backend->kind || 'backend');
  my ($op, $rest) = (($sql =~ m/^(\w+)(.+)$/), 'NOP', ' NO SQL');

  return do {
    if ((reftype($dsn) || '') ne 'CODE' && defined $dsn) {
      "$op [DSN_$kind=$dsn]$rest";
    }
    elsif (my $id = eval { $self->backend->id }) {
      "$op [$kind=$id]$rest";
    }
    else {
      "$op [$kind]$rest";
    }
  };
}

1;
