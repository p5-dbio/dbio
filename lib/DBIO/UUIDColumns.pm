package DBIO::UUIDColumns;

# ABSTRACT: Implicit UUID columns for DBIO

use strict;
use warnings;

use base qw/DBIO::Base/;

__PACKAGE__->mk_group_accessors('inherited', qw/uuid_auto_columns uuid_maker/);
__PACKAGE__->uuid_class(__PACKAGE__->_find_uuid_module);

=head1 SYNOPSIS

In your L<DBIO> Result class:

  __PACKAGE__->load_components(qw/UUIDColumns/);
  __PACKAGE__->uuid_columns('artist_id');

=head1 DESCRIPTION

This L<DBIO> component automatically generates UUID values for designated
columns on insert. Based on L<DBIx::Class::UUIDColumns> by Chia-liang Kao
and Chris Laco.

When loaded, C<UUIDColumns> will search for a suitable UUID generation module
from the following list:

  Data::UUID
  UUID
  UUID::Random

If no supporting module can be found, an exception will be thrown.

You can also specify a particular module:

  __PACKAGE__->uuid_class('Data::UUID');

=cut

=attr uuid_auto_columns

Configured list of columns that should receive generated UUID values.

=attr uuid_maker

Selected UUID generator class/module.

=method uuid_columns

Get or set UUID-managed columns for this result class.

=cut

sub uuid_columns {
  my $self = shift;
  if (scalar @_) {
    for (@_) {
      $self->throw_exception("column $_ doesn't exist") unless $self->has_column($_);
    }
    $self->uuid_auto_columns(\@_);
  }
  return $self->uuid_auto_columns || [];
}

=method uuid_class

Get or set the UUID generator implementation class.

=cut

sub uuid_class {
  my ($self, $class) = @_;
  if ($class) {
    if (!eval "require $class; 1") {
      $self->throw_exception("$class could not be loaded: $@");
    }
    $self->uuid_maker($class);
  }
  return $self->uuid_maker;
}

=method insert

Populate missing configured UUID columns before insert.

=cut

sub insert {
  my $self = shift;
  for my $column (@{$self->uuid_columns}) {
    $self->store_column($column, $self->get_uuid)
      unless defined $self->get_column($column);
  }
  $self->next::method(@_);
}

=method get_uuid

Generate one UUID value using the configured generator.

=cut

sub get_uuid {
  my $self = shift;
  my $class = $self->uuid_maker;
  if ($class eq 'Data::UUID') {
    return Data::UUID->new->create_str;
  } elsif ($class eq 'UUID') {
    my ($uuid, $string);
    UUID::generate($uuid);
    UUID::unparse($uuid, $string);
    return $string;
  } elsif ($class eq 'UUID::Random') {
    return UUID::Random::generate();
  } else {
    # generic fallback: try ->new->as_string
    return $class->new->as_string;
  }
}

=method _find_uuid_module

Discover the first available UUID generation backend.

=cut

sub _find_uuid_module {
  if (eval { require Data::UUID; 1 }) {
    return 'Data::UUID';
  } elsif (eval { require UUID; 1 }) {
    return 'UUID';
  } elsif (eval { require UUID::Random; 1 }) {
    return 'UUID::Random';
  } else {
    die 'No suitable UUID module found. Install Data::UUID, UUID, or UUID::Random';
  }
}

1;
