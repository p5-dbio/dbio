package DBIO::Test::Schema::MooseSugar::ResultSet::Artist;
# ABSTRACT: Custom Moose-based ResultSet for the MooseSugar artist source

use Moose;
use MooseX::NonMoose;
extends 'DBIO::ResultSet';

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
