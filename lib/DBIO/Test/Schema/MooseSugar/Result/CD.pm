package DBIO::Test::Schema::MooseSugar::Result::CD;
# ABSTRACT: Moose + Cake test result class for the cd table (no custom ResultSet)

use DBIO::Moose;
use DBIO::Cake;

table 'cd';

col id        => integer auto_inc;
col artist_id => integer;
col title     => varchar(100);
col year      => integer null;

primary_key 'id';

__PACKAGE__->belongs_to( artist => 'DBIO::Test::Schema::MooseSugar::Result::Artist', 'artist_id' );

has full_title => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_full_title',
);
sub _build_full_title {
  my $self = shift;
  my $year = $self->year // '?';
  sprintf '%s (%s)', $self->title, $year;
}

has rating => ( is => 'rw', isa => 'Int', lazy => 1, default => 0 );

__PACKAGE__->meta->make_immutable;

1;
