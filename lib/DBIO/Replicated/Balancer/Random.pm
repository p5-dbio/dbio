package DBIO::Replicated::Balancer::Random;
# ABSTRACT: Randomly choose an active replicant

use strict;
use warnings;

use base 'DBIO::Replicated::Balancer';

__PACKAGE__->mk_group_accessors(simple => 'master_read_weight');

sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->master_read_weight(exists $args{master_read_weight} ? $args{master_read_weight} : 0);
  return $self;
}

sub next_storage {
  my $self = shift;

  my @replicants = $self->pool->active_replicants;
  return if not @replicants;

  my $rnd = $self->_random_number(@replicants + $self->master_read_weight);
  return $rnd >= @replicants ? $self->master : $replicants[int $rnd];
}

sub _random_number {
  rand($_[1]);
}

1;
