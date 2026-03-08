package DBIO::InflateColumn::Serializer::MessagePack;
# ABSTRACT: MessagePack Inflator

use strict;
use warnings;
use Data::MessagePack;
use Carp;
use namespace::clean;

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::Serializer');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'BLOB',
      'serializer_class'   => 'MessagePack'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database
in MessagePack format. MessagePack is a compact binary serialization format,
ideal for columns where space efficiency matters.

Requires L<Data::MessagePack>.

=method get_freezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that serializes
the data passed to it. Returns a coderef.

=cut

sub get_freezer {
  my ($class, $column, $info, $args) = @_;

  my $mp = Data::MessagePack->new->utf8;

  if (defined $info->{'size'}){
      my $size = $info->{'size'};
      return sub {
        my $s = $mp->pack(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return $mp->pack(shift);
      };
  }
}

=method get_unfreezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that deserializes
the data stored in the column. Returns a coderef.

=cut

sub get_unfreezer {
  my ($class, $column, $info, $args) = @_;

  my $mp = Data::MessagePack->new->utf8;
  return sub {
    $mp->unpack(shift);
  };
}


1;
