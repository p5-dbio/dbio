package DBIO::Test::Schema::Moose::ResultSet::Artist;
# ABSTRACT: Custom Moose-schema ResultSet for the artist source

use strict;
use warnings;

use base 'DBIO::ResultSet';

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

1;
