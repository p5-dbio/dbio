package DBIO::Test::Schema::Moose;
# ABSTRACT: Test schema with Moose-enabled result classes

use strict;
use warnings;

use Moose;
extends 'DBIO::Schema';

# Schema-level Moose attribute — demonstrates Moose on the schema class itself
has verbose => ( is => 'rw', isa => 'Bool', lazy => 1, default => 0 );

__PACKAGE__->load_classes(
  { 'DBIO::Test::Schema::Moose' => [qw( Result::Artist Result::CD )] }
);

__PACKAGE__->meta->make_immutable;

1;
