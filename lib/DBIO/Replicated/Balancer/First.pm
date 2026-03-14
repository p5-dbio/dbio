package DBIO::Replicated::Balancer::First;
# ABSTRACT: Always use the first active replicant

use strict;
use warnings;

use base 'DBIO::Replicated::Balancer';

sub next_storage {
  return (shift->pool->active_replicants)[0];
}

1;
