package DBIO::Test::Schema::Moo;
# ABSTRACT: Test schema with Moo-enabled result classes

use strict;
use warnings;

use Moo;
extends 'DBIO::Schema';

# Schema-level Moo attribute — demonstrates Moo on the schema class itself
has verbose => ( is => 'rw', lazy => 1, default => sub { 0 } );

__PACKAGE__->load_classes(
  { 'DBIO::Test::Schema::Moo' => [qw( Result::Artist Result::CD )] }
);

1;
