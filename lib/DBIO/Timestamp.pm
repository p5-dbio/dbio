package DBIO::Timestamp;
# ABSTRACT: Automatically set and update timestamp columns

use strict;
use warnings;
use DateTime;

sub add_columns {
  my ($self, @cols) = @_;
  my @columns;

  while (my $col = shift @cols) {
    my $info = ref $cols[0] ? shift @cols : {};

    if (delete $info->{set_on_create}) {
      $info->{_timestamp_on_create} = 1;
    }

    if (delete $info->{set_on_update}) {
      $info->{_timestamp_on_update} = 1;
    }

    push @columns, $col => $info;
  }

  return $self->next::method(@columns);
}

sub insert {
  my $self = shift;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_timestamp_on_create};
    next if defined $self->get_column($col);
    $self->store_column($col => $self->get_timestamp);
  }

  return $self->next::method(@_);
}

sub update {
  my $self = shift;
  my $upd  = shift;

  $self->set_inflated_columns($upd) if $upd;

  my $columns_info = $self->result_source->columns_info;
  for my $col (keys %$columns_info) {
    next unless $columns_info->{$col}{_timestamp_on_update};
    $self->set_inflated_columns({ $col => $self->get_timestamp });
  }

  return $self->next::method(@_);
}

=method get_timestamp

Returns a L<DateTime> object for the current time. Override this in your
Result class to customize (e.g. set a specific timezone).

=cut

sub get_timestamp {
  return DateTime->now;
}

1;

__END__

=head1 SYNOPSIS

  package MyApp::Schema::Result::Article;
  use base 'DBIO::Core';

  __PACKAGE__->load_components(qw/Timestamp/);
  __PACKAGE__->table('article');
  __PACKAGE__->add_columns(
    id         => { data_type => 'integer', is_auto_increment => 1 },
    title      => { data_type => 'varchar', size => 255 },
    created_at => { data_type => 'datetime', set_on_create => 1 },
    updated_at => { data_type => 'datetime', set_on_create => 1, set_on_update => 1 },
  );

=head1 DESCRIPTION

Automatically sets timestamp columns on insert and update. Columns with
C<set_on_create> are populated when a new row is inserted. Columns with
C<set_on_update> are refreshed on every update.

Explicitly provided values are respected (noclobber on create; update
always refreshes).
