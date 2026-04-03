package DBIO::Test::Schema::MooseSugar;
# ABSTRACT: Test schema with Moose + DBIO::Cake result classes

use strict;
use warnings;

use Moose;
extends 'DBIO::Schema';

has verbose => ( is => 'rw', isa => 'Bool', lazy => 1, default => 0 );

__PACKAGE__->load_namespaces;

__PACKAGE__->meta->make_immutable;

1;
