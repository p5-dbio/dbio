package DBIO::Test::Schema::MooCake::Result::Artist;
# ABSTRACT: Moo + Cake test result class for the artist table

use DBIO::Moo;
use DBIO::Cake;

table 'artist';

col id   => integer auto_inc;
col name => varchar(100);

primary_key 'id';

__PACKAGE__->has_many( cds => 'DBIO::Test::Schema::MooCake::Result::CD', 'artist_id' );

__PACKAGE__->resultset_class('DBIO::Test::Schema::MooCake::ResultSet::Artist');

has display_name => ( is => 'lazy' );
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => ( is => 'rw', lazy => 1, default => sub { 0 } );

1;
