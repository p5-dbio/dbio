package DBIO::Test::Schema::MooCake::Result::CD;
# ABSTRACT: Moo + Cake test result class for the cd table (no custom ResultSet)

use DBIO::Moo;
use DBIO::Cake;

table 'cd';

col id        => integer auto_inc;
col artist_id => integer;
col title     => varchar(100);
col year      => integer null;

primary_key 'id';

__PACKAGE__->belongs_to( artist => 'DBIO::Test::Schema::MooCake::Result::Artist', 'artist_id' );

has full_title => ( is => 'lazy' );
sub _build_full_title {
  my $self = shift;
  my $year = $self->year // '?';
  sprintf '%s (%s)', $self->title, $year;
}

has rating => ( is => 'rw', lazy => 1, default => sub { 0 } );

1;
