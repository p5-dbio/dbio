package DBIO::InflateColumn::Serializer::YAML;
# ABSTRACT: YAML Inflator

use strict;
use warnings;
use YAML;
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
      'serializer_class'   => 'YAML'
    }
  );

Then in your code...

  my $struct = { 'I' => { 'am' => 'a struct' } };
  $obj->data_column($struct);
  $obj->update;

And you can recover your data structure with:

  my $obj = ...->find(...);
  my $struct = $obj->data_column;

The data structures you assign to C<data_column> are saved in YAML format.

=head1 DESCRIPTION

YAML backend for L<DBIO::InflateColumn::Serializer>. Loaded
automatically when a column declares
C<< serializer_class => 'YAML' >>.

=head1 COLUMN INFO

=over 4

=item C<< serializer_class => 'YAML' >>

Selects this backend.

=item C<< size => $n >>

Optional. Serialised payload is checked against C<size> on deflate;
over-long payloads throw.

=back

=head1 DEPENDENCIES

L<YAML>. Not a hard dependency of DBIO; install separately.

=method get_freezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that serializes
the data passed to it. Returns a coderef.

=cut

sub get_freezer {
  my ($class, $column, $info, $args) = @_;

  if (defined $info->{'size'}){
      my $size = $info->{'size'};
      return sub {
        my $s = YAML::Dump(shift);
        croak "serialization too big" if (length($s) > $size);
        return $s;
      };
  } else {
      return sub {
        return YAML::Dump(shift);
      };
  }
}

=method get_unfreezer

Called by L<DBIO::InflateColumn::Serializer> to get the routine that deserializes
the data stored in the column. Returns a coderef.

=cut

sub get_unfreezer {
  return sub {
    return YAML::Load(shift);
  };
}


1;
