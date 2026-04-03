package DBIO::Test::Schema::Moose;
# ABSTRACT: Test schema with Moose-enabled result classes

use strict;
use warnings;

use base 'DBIO::Schema';

__PACKAGE__->load_classes(
  { 'DBIO::Test::Schema::Moose' => [qw( Result::Artist Result::CD )] }
);

1;
