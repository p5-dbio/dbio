package DBIO::Test::Schema::MooseSugar::Result::Artist;
# ABSTRACT: Moose + Cake test result class for the artist table

use DBIO::Moose;
use DBIO::Cake;

table 'artist';

col id   => integer auto_inc;
col name => varchar(100);

primary_key 'id';

__PACKAGE__->has_many( cds => 'DBIO::Test::Schema::MooseSugar::Result::CD', 'artist_id' );

__PACKAGE__->resultset_class('DBIO::Test::Schema::MooseSugar::ResultSet::Artist');

has display_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;
