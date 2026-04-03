package DBIO::Test::Schema::MooCake;
# ABSTRACT: Test schema with Moo + DBIO::Cake result classes

use strict;
use warnings;

use Moo;
extends 'DBIO::Schema';

has verbose => ( is => 'rw', lazy => 1, default => sub { 0 } );

__PACKAGE__->load_namespaces;

1;
