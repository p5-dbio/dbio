# ABSTRACT: Read replica pool with round-robin
package DBIO::AccessBroker::ReadWrite;

use strict;
use warnings;
use Carp qw(croak);
use base 'DBIO::AccessBroker';
use namespace::clean;

__PACKAGE__->mk_group_accessors('simple' => qw(
  _write_info _read_infos _read_index
));

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);

  my $write = $args{write} // croak "ReadWrite broker requires 'write'";
  my $read  = $args{read}  // croak "ReadWrite broker requires 'read'";
  $read = [$read] if ref $read eq 'HASH';

  $self->_write_info($write);
  $self->_read_infos([map { $_ } @$read]);
  $self->_read_index(0);

  return $self;
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

sub has_read_write_routing { 1 }

1;

=head1 DESCRIPTION

Read/write brokers route reads and writes to different endpoints and are
therefore not transaction-safe by default. See
L<DBIO::AccessBroker/TRANSACTION SAFETY>.
