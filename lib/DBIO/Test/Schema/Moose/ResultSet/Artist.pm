package DBIO::Test::Schema::Moose::ResultSet::Artist;
# ABSTRACT: Custom Moose-based ResultSet for the artist source

use Moose;
use MooseX::NonMoose;
extends 'DBIO::ResultSet';

# MooseX::NonMoose's default FOREIGNBUILDARGS is a pass-through — correct
# for ResultSet: no key filtering needed unlike DBIO::Row::new.

# ResultSet-level Moose attribute
has default_limit => ( is => 'rw', isa => 'Int', lazy => 1, default => 100 );

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

__PACKAGE__->meta->make_immutable;

1;
