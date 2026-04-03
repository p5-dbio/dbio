package DBIO::Test::Schema::MooCake::ResultSet::Artist;
# ABSTRACT: Custom Moo-based ResultSet for the MooCake artist source

use Moo;
extends 'DBIO::ResultSet';

sub FOREIGNBUILDARGS { my ($class, @args) = @_; return @args }

has default_limit => ( is => 'rw', lazy => 1, default => sub { 100 } );

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

1;
