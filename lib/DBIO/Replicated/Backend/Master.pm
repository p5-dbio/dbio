package DBIO::Replicated::Backend::Master;
# ABSTRACT: Master backend wrapper

use strict;
use warnings;

use base 'DBIO::Replicated::Backend';

sub new {
  my ($class, %args) = @_;
  $args{kind} = 'master';
  return $class->SUPER::new(%args);
}

1;
