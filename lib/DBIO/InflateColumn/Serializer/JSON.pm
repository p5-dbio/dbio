package DBIO::InflateColumn::Serializer::JSON;
# ABSTRACT: JSON Inflator

use strict;
use warnings;
use JSON::MaybeXS;
use Carp;
use namespace::clean;

=head1 SYNOPSIS

  package MySchema::Table;
  use base 'DBIO::Core';

  __PACKAGE__->load_components('InflateColumn::Serializer');
  __PACKAGE__->add_columns(
    'data_column' => {
      'data_type' => 'VARCHAR',
      'size'      => 255,
      'serializer_class'   => 'JSON',
      'serializer_options' => { allow_blessed => 1, convert_blessed => 1, pretty => 1 },    # optional
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to "data_column" will be saved in the database in JSON format.

Any arguments included in C<serializer_options> are passed to the
L<JSON::MaybeXS> constructor used for serialization and deserialization.

=method get_freezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that serializes
the data passed to it. Returns a coderef.

=cut

sub get_freezer {
  my ($class, $column, $info, $args) = @_;

  my $opts = $info->{serializer_options};

  my $serializer = JSON::MaybeXS->new($opts && %$opts ? %$opts: ());

  if (defined $info->{'size'}){
      my $size = $info->{'size'};

      return sub {
        my $s = $serializer->encode(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return $serializer->encode(shift);
      };
  }
}

=method get_unfreezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that deserializes
the data stored in the column. Returns a coderef.

=cut

sub get_unfreezer {
  my ($class, $column, $info, $args) = @_;

  my $opts = $info->{serializer_options};
  return sub {
    JSON::MaybeXS->new($opts && %$opts ? %$opts : ())->decode(shift);
  };
}


1;
