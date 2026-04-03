package DBIO::Test::Schema::Moo;
# ABSTRACT: Test schema with Moo-enabled result classes

use strict;
use warnings;

use base 'DBIO::Schema';

__PACKAGE__->load_classes(
  { 'DBIO::Test::Schema::Moo' => [qw( Result::Artist Result::CD )] }
);

1;
