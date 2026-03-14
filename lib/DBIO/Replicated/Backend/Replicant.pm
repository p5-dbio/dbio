package DBIO::Replicated::Backend::Replicant;
# ABSTRACT: Replicant backend wrapper

use strict;
use warnings;

use base 'DBIO::Replicated::Backend';

sub new {
  my ($class, %args) = @_;
  $args{kind} = 'replicant';
  $args{active} = 1 unless exists $args{active};
  return $class->SUPER::new(%args);
}

sub debugobj {
  my $self = shift;
  return $self->master->debugobj(@_) if $self->master;
  return $self->SUPER::debugobj(@_);
}

1;
