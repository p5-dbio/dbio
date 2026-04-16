package DBIO::ResultSourceProxy::Table;
# ABSTRACT: provides a classdata table object and method proxies

use strict;
use warnings;

use base qw/DBIO::ResultSourceProxy/;

use DBIO::ResultSource::Table;
use Scalar::Util 'blessed';
use namespace::clean;

__PACKAGE__->mk_classdata(table_class => 'DBIO::ResultSource::Table');

__PACKAGE__->mk_classdata('table_alias'); # FIXME: Doesn't actually do
                                          # anything yet!

sub _init_result_source_instance {
    my $class = shift;

    $class->mk_classdata('result_source_instance')
        unless $class->can('result_source_instance');

    my $table = $class->result_source_instance;
    my $class_has_table_instance = ($table and $table->result_class eq $class);
    return $table if $class_has_table_instance;

    my $table_class = $class->table_class;
    $class->ensure_class_loaded($table_class);

    if( $table ) {
        $table = $table_class->new({
            %$table,
            result_class => $class,
            source_name => undef,
            schema => undef
        });
    }
    else {
        $table = $table_class->new({
            name            => undef,
            result_class    => $class,
            source_name     => undef,
        });
    }

    $class->result_source_instance($table);

    return $table;
}

=head1 SYNOPSIS

  __PACKAGE__->table('cd');
  __PACKAGE__->add_columns(qw/cdid artist title year/);
  __PACKAGE__->set_primary_key('cdid');

=head1 METHODS

=method add_columns

  __PACKAGE__->add_columns(qw/cdid artist title year/);

Adds columns to the current class and creates accessors for them.

=cut

=method table

  __PACKAGE__->table('tbl_name');

Gets or sets the table name.

=cut

=method indices

  __PACKAGE__->indices(
    name_idx       => 'name',
    name_city_idx => ['name', 'city'],
  );

Declares one or more secondary indexes on the table. Field lists may be a
single column name or an arrayref of column names. Equivalent to the
L<DBICx::Indexing> component on DBIx::Class.

The indexes are picked up by both the SQL::Translator deploy path (via
C<sqlt_deploy_hook>) and the native PostgreSQL deploy path (via
C<pg_indexes>). A hashref argument is also accepted:

  __PACKAGE__->indices({ name_idx => 'name' });

=cut

sub indices {
  my $class = shift;
  my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

  my $source = $class->result_source_instance;
  my $list = $source->{_cake_indexes} ||= [];
  for my $name (sort keys %args) {
    my $fields = $args{$name};
    $fields = [ $fields ] unless ref $fields eq 'ARRAY';
    push @$list, { name => $name, fields => $fields };
  }

  $class->_install_index_hooks($source);
  return;
}

# Idempotent installer for the two deploy paths that pick up the
# _cake_indexes source slot: the SQL::Translator hook (legacy drivers)
# and the native PostgreSQL pg_indexes class method. Shared with
# DBIO::Cake's idx() so both DSLs end up with the same hook layout.
sub _install_index_hooks {
  my ($class, $source) = @_;

  unless ($source->{_cake_hook_installed}) {
    $source->{_cake_hook_installed} = 1;
    my $orig_hook = $class->can('sqlt_deploy_hook');
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::sqlt_deploy_hook"} = sub {
      my ($self_or_class, $sqlt_table) = @_;
      $orig_hook->($self_or_class, $sqlt_table) if $orig_hook;
      my $src = $self_or_class->isa('DBIO::ResultSource')
        ? $self_or_class
        : $self_or_class->result_source_instance;
      my $idxs = $src->{_cake_indexes} || [];
      for my $idx (@$idxs) {
        $sqlt_table->add_index(
          name   => $idx->{name},
          fields => $idx->{fields},
          (exists $idx->{type}    ? (type    => $idx->{type})    : ()),
          (exists $idx->{options} ? (options => $idx->{options}) : ()),
        );
      }
    };
  }

  unless ($source->{_cake_pg_indexes_installed}) {
    $source->{_cake_pg_indexes_installed} = 1;
    my $orig_pg_indexes = $class->can('pg_indexes');
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::pg_indexes"} = sub {
      my $invocant = shift;
      my $src = (ref $invocant && $invocant->isa('DBIO::ResultSource'))
        ? $invocant
        : (ref $invocant ? ref($invocant) : $invocant)->result_source_instance;
      my %result = $orig_pg_indexes ? %{ $orig_pg_indexes->($invocant, @_) || {} } : ();
      my $idxs = $src->{_cake_indexes} || [];
      for my $idx (@$idxs) {
        my %entry = (
          columns => $idx->{fields},
          (($idx->{type} // '') =~ /^unique$/i ? (unique => 1) : ()),
        );
        if (my $pg = $idx->{pg}) {
          $entry{where}      = $pg->{where}      if exists $pg->{where};
          $entry{using}      = $pg->{using}      if exists $pg->{using};
          $entry{with}       = $pg->{with}       if exists $pg->{with};
          $entry{expression} = $pg->{expression} if exists $pg->{expression};
        }
        $result{$idx->{name}} = \%entry;
      }
      return \%result;
    };
  }
}

sub table {
  my ($class, $table) = @_;
  return $class->result_source_instance->name unless $table;

  unless (blessed $table && $table->isa($class->table_class)) {

    my $table_class = $class->table_class;
    $class->ensure_class_loaded($table_class);

    $table = $table_class->new({
        $class->can('result_source_instance')
          ? %{$class->result_source_instance||{}}
          : ()
        ,
        name => $table,
        result_class => $class,
    });
  }

  $class->mk_classdata('result_source_instance')
    unless $class->can('result_source_instance');

  $class->result_source_instance($table);

  return $class->result_source_instance->name;
}

=method table_class

  __PACKAGE__->table_class('DBIO::ResultSource::Table');

Gets or sets the table class used for construction and validation.

=method has_column

  if ($obj->has_column($col)) { ... }

Returns 1 if the class has a column of this name, 0 otherwise.

=method column_info

  my $info = $obj->column_info($col);

Returns the column metadata hashref for a column. For a description of
the various types of column data in this hashref, see
L<DBIO::ResultSource/add_column>

=method columns

  my @column_names = $obj->columns;

=cut

1;


