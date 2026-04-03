package # hide from PAUSE
    DBIO::Test::Schema::Moose::Result::Artist;
# ABSTRACT: Moose-enabled test result class for the artist table

use DBIO::Moose;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 100, is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  cds => 'DBIO::Test::Schema::Moose::Result::CD', 'artist_id'
);

# Lazy Moose attribute — computed from column data on first access
has display_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

# Moose rw attribute with type constraint and lazy default
# (must be lazy — inflate_result bypasses new())
has score => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;
