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

=head2 add_columns

  __PACKAGE__->add_columns(qw/cdid artist title year/);

Adds columns to the current class and creates accessors for them.

=cut

=head2 table

  __PACKAGE__->table('tbl_name');

Gets or sets the table name.

=cut

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

=head2 table_class

  __PACKAGE__->table_class('DBIO::ResultSource::Table');

Gets or sets the table class used for construction and validation.

=head2 has_column

  if ($obj->has_column($col)) { ... }

Returns 1 if the class has a column of this name, 0 otherwise.

=head2 column_info

  my $info = $obj->column_info($col);

Returns the column metadata hashref for a column. For a description of
the various types of column data in this hashref, see
L<DBIO::ResultSource/add_column>

=head2 columns

  my @column_names = $obj->columns;

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;


