package # hide from PAUSE
    DBIO::Test::Schema::Moo::Result::Artist;
# ABSTRACT: Moo-enabled test result class for the artist table

use DBIO::Moo;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 100, is_nullable => 0 },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
  cds => 'DBIO::Test::Schema::Moo::Result::CD', 'artist_id'
);

# Lazy Moo attribute — computed from column data on first access
has display_name => ( is => 'lazy' );
sub _build_display_name { 'Artist: ' . $_[0]->name }

# Moo rw attribute with a lazy default (must be lazy — inflate_result bypasses new())
has score => ( is => 'rw', lazy => 1, default => sub { 0 } );

1;
