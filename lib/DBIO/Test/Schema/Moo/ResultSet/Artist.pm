package DBIO::Test::Schema::Moo::ResultSet::Artist;
# ABSTRACT: Custom Moo-based ResultSet for the artist source

use Moo;
extends 'DBIO::ResultSet';

# For Moo extending a non-Moo class: pass constructor args through unchanged.
# DBIO::ResultSet::new takes ($source_handle, \%attrs) — no filtering needed.
sub FOREIGNBUILDARGS { my ($class, @args) = @_; return @args }

# ResultSet-level Moo attribute
has default_limit => ( is => 'rw', lazy => 1, default => sub { 100 } );

sub by_name {
  my ($self, $name) = @_;
  return $self->search({ name => $name });
}

sub order_by_name {
  return $_[0]->search({}, { order_by => { -asc => 'name' } });
}

1;
