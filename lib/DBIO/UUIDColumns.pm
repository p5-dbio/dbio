package DBIO::UUIDColumns;
# ABSTRACT: Automatically populate UUID columns on insert

use strict;
use warnings;

use base qw/DBIO::Base/;

__PACKAGE__->mk_classdata('uuid_maker');
__PACKAGE__->uuid_class(__PACKAGE__->_find_uuid_module);

sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (delete $info->{uuid_on_create}) {
      $info->{_uuid_on_create} = 1;
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}

sub insert {
  my $self = shift;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_uuid_on_create};
    next if defined $self->get_column($col);
    $self->store_column($col => $self->get_uuid);
  }

  return $self->next::method(@_);
}

=method uuid_class

  __PACKAGE__->uuid_class('Data::UUID');

Class-level accessor. Selects the UUID generator backend. Defaults to
the first installed backend among C<Data::UUID>, C<UUID>, and
C<UUID::Random>.

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

=method get_uuid

Returns one freshly generated UUID string from the configured backend.
Override this in your Result class to customize.

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
    return $class->new->as_string;
  }
}

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

__END__

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/UUIDColumns/);
  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(
    artist_id => { data_type => 'varchar', size => 36, uuid_on_create => 1 },
    name      => { data_type => 'varchar', size => 100 },
  );
  __PACKAGE__->set_primary_key('artist_id');

=head1 DESCRIPTION

Automatically populates columns marked with C<uuid_on_create> with a
freshly generated UUID at insert time. Existing values are respected --
only undefined columns receive a generated UUID.

The generator backend is selected once per class via L</uuid_class>.
By default the first installed backend among L<Data::UUID>, L<UUID>,
and L<UUID::Random> is used. If none of these are installed, loading
this component throws an exception.

Based on L<DBIx::Class::UUIDColumns> by Chia-liang Kao and Chris Laco.

=cut
