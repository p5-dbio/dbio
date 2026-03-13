package DBIO::Cake;
# ABSTRACT: DDL-like DSL for defining DBIO result classes

use strict;
use warnings;

our @EXPORT;
our %EXPORT_TAGS;

my @col_types = qw(
  integer tinyint smallint bigint
  serial bigserial smallserial
  numeric decimal
  real float4 double float8 float
  char varchar
  text tinytext mediumtext longtext
  blob tinyblob mediumblob longblob bytea
  boolean bool
  date datetime timestamp time timetz timestamptz interval
  enum uuid json jsonb xml hstore
  array
  money
  vector halfvec sparsevec bit varbit
  inet cidr macaddr macaddr8
  tsvector tsquery
  point line lseg box path polygon circle
  int4range int8range numrange tsrange tstzrange daterange
);

my @col_modifiers = qw(
  null auto_inc fk default unsigned
);

my @table_funcs = qw(
  table col primary_key unique
);

my @relationship_funcs = qw(
  belongs_to has_one has_many might_have many_to_many
  rel_one rel_many
);

my @cascade_funcs = qw(
  ddl_cascade dbic_cascade
);

my @other_funcs = qw(
  view idx
);

@EXPORT = (
  @col_types, @col_modifiers,
  @table_funcs, @relationship_funcs,
  @cascade_funcs, @other_funcs,
);

# Per-caller options storage
my %CALLER_OPTS;

sub import {
  my ($class, @args) = @_;
  my $caller = caller;

  # Parse import options
  my %opts = (
    autoclean => 1,
    inflate_datetime => 0,
    inflate_json => 0,
    retrieve_defaults => 0,
  );

  my @components;

  while (my $arg = shift @args) {
    if ($arg eq '-V2') {
      # default and only version, no-op
    }
    elsif ($arg eq '-inflate_datetime') {
      $opts{inflate_datetime} = 1;
    }
    elsif ($arg eq '-inflate_json') {
      $opts{inflate_json} = 1;
    }
    elsif ($arg eq '-retrieve_defaults') {
      $opts{retrieve_defaults} = 1;
    }
    elsif ($arg eq '-autoclean') {
      $opts{autoclean} = 1;
    }
    elsif ($arg eq '-no_autoclean') {
      $opts{autoclean} = 0;
    }
  }

  # Enable strict and warnings in caller
  strict->import;
  warnings->import;

  # Set up inheritance — caller ISA DBIO::Core
  {
    no strict 'refs';
    unless ($caller->isa('DBIO::Core')) {
      require DBIO::Core;
      push @{"${caller}::ISA"}, 'DBIO::Core';
    }
  }

  # Load optional components
  if ($opts{inflate_datetime}) {
    push @components, 'InflateColumn::DateTime';
  }
  if (@components) {
    $caller->load_components(@components);
  }

  # Store per-caller options
  $CALLER_OPTS{$caller} = \%opts;

  # Export all DSL functions into the caller
  {
    no strict 'refs';
    for my $func (@EXPORT) {
      *{"${caller}::${func}"} = \&{$func};
    }
  }

  # Schedule namespace cleanup at end of caller's scope
  if ($opts{autoclean}) {
    require namespace::clean;
    namespace::clean->import(
      -cleanee => $caller,
      @EXPORT,
    );
  }
}

# --- Internal helpers ---

sub _caller_class {
  # Walk up the call stack to find the result class (skip DBIO::Cake frames)
  my $i = 1;
  while (my $pkg = caller($i)) {
    return $pkg unless $pkg eq __PACKAGE__;
    $i++;
  }
  return caller(1);
}

sub _expand_col_options {
  my (@args) = @_;
  my %merged;

  while (@args) {
    my $key = shift @args;
    my $val = shift @args;

    if ($key =~ /^(.+?)\.(.+)$/) {
      # Dotted notation: e.g. extra.unsigned => 1 becomes { extra => { unsigned => 1 } }
      my ($outer, $inner) = ($1, $2);
      $merged{$outer} ||= {};
      $merged{$outer}{$inner} = $val;
    }
    else {
      $merged{$key} = $val;
    }
  }

  return %merged;
}

# --- Table declaration ---

sub table {
  my ($name) = @_;
  my $class = _caller_class();
  $class->table($name);
}

# --- Column declaration ---

sub col {
  my ($name, @options) = @_;
  my $class = _caller_class();

  my %info = _expand_col_options(@options);

  # Default: not nullable
  $info{is_nullable} = 0 unless exists $info{is_nullable};

  # If -retrieve_defaults is active and there is a default_value,
  # set retrieve_on_insert
  my $opts = $CALLER_OPTS{$class};
  if ($opts && $opts->{retrieve_defaults} && exists $info{default_value}) {
    $info{retrieve_on_insert} = 1 unless exists $info{retrieve_on_insert};
  }

  # If -inflate_json and column is json/jsonb, set up serialization
  if ($opts && $opts->{inflate_json}) {
    my $dt = $info{data_type} || '';
    if ($dt eq 'json' || $dt eq 'jsonb') {
      $info{serializer_class} = 'JSON' unless exists $info{serializer_class};
    }
  }

  $class->add_columns($name => \%info);
}

# --- Column modifiers (return key-value pairs) ---

sub null { return (is_nullable => 1) }

sub auto_inc { return (is_auto_increment => 1) }

sub fk { return (is_foreign_key => 1) }

sub unsigned { return ('extra.unsigned' => 1) }

sub default {
  my ($val) = @_;
  return (default_value => $val);
}

# --- Column type functions (return key-value pairs) ---

# Integers
sub integer    { return (data_type => 'integer') }
sub tinyint    { return (data_type => 'tinyint') }
sub smallint   { return (data_type => 'smallint') }
sub bigint     { return (data_type => 'bigint') }

# Serial (auto-increment integer shortcuts)
sub serial      { return (data_type => 'serial', is_auto_increment => 1) }
sub bigserial   { return (data_type => 'bigserial', is_auto_increment => 1) }
sub smallserial { return (data_type => 'smallserial', is_auto_increment => 1) }

# Numeric
sub numeric {
  my ($precision, $scale) = @_;
  my @r = (data_type => 'numeric');
  push @r, (size => [$precision, $scale]) if defined $precision;
  return @r;
}

sub decimal {
  my ($precision, $scale) = @_;
  my @r = (data_type => 'decimal');
  push @r, (size => [$precision, $scale]) if defined $precision;
  return @r;
}

# Floats
sub real   { return (data_type => 'real') }
sub float4 { return (data_type => 'real') }
sub double { return (data_type => 'double precision') }
sub float8 { return (data_type => 'double precision') }

sub float {
  my ($bits) = @_;
  my @r = (data_type => 'float');
  push @r, (size => $bits) if defined $bits;
  return @r;
}

# Strings
sub char {
  my ($size) = @_;
  return (data_type => 'char', size => ($size || 1));
}

sub varchar {
  my ($size) = @_;
  return (data_type => 'varchar', size => ($size || 255));
}

# Text
sub text       { return (data_type => 'text') }
sub tinytext   { return (data_type => 'tinytext') }
sub mediumtext { return (data_type => 'mediumtext') }
sub longtext   { return (data_type => 'longtext') }

# Binary
sub blob       { return (data_type => 'blob') }
sub tinyblob   { return (data_type => 'tinyblob') }
sub mediumblob { return (data_type => 'mediumblob') }
sub longblob   { return (data_type => 'longblob') }
sub bytea      { return (data_type => 'bytea') }

# Boolean
sub boolean { return (data_type => 'boolean') }
sub bool    { return (data_type => 'boolean') }

# Date/Time
sub date { return (data_type => 'date') }

sub datetime {
  my ($tz) = @_;
  my @r = (data_type => 'datetime');
  push @r, (timezone => $tz) if defined $tz;
  return @r;
}

sub timestamp {
  my ($tz) = @_;
  my @r = (data_type => 'timestamp');
  push @r, (timezone => $tz) if defined $tz;
  return @r;
}

sub time {
  my ($tz) = @_;
  my @r = (data_type => 'time');
  push @r, (timezone => $tz) if defined $tz;
  return @r;
}

sub timetz      { return (data_type => 'time with time zone') }
sub timestamptz { return (data_type => 'timestamp with time zone') }
sub interval    { return (data_type => 'interval') }

# Enum
sub enum {
  my (@values) = @_;
  return (data_type => 'enum', extra => { list => [@values] });
}

# UUID
sub uuid { return (data_type => 'uuid') }

# JSON
sub json  { return (data_type => 'json') }
sub jsonb { return (data_type => 'jsonb') }

# XML / hstore
sub xml    { return (data_type => 'xml') }
sub hstore { return (data_type => 'hstore') }

# Array (PostgreSQL)
sub array {
  my ($type_info) = @_;
  if (ref $type_info eq 'HASH') {
    return (data_type => 'ARRAY', %$type_info);
  }
  return (data_type => $type_info . '[]');
}

# Money
sub money { return (data_type => 'money') }

# Vector / AI (pgvector)
sub vector {
  my ($dims) = @_;
  my @r = (data_type => 'vector');
  push @r, (size => $dims) if defined $dims;
  return @r;
}

sub halfvec {
  my ($dims) = @_;
  my @r = (data_type => 'halfvec');
  push @r, (size => $dims) if defined $dims;
  return @r;
}

sub sparsevec {
  my ($dims) = @_;
  my @r = (data_type => 'sparsevec');
  push @r, (size => $dims) if defined $dims;
  return @r;
}

# Bit strings
sub bit {
  my ($size) = @_;
  my @r = (data_type => 'bit');
  push @r, (size => $size) if defined $size;
  return @r;
}

sub varbit {
  my ($size) = @_;
  my @r = (data_type => 'varbit');
  push @r, (size => $size) if defined $size;
  return @r;
}

# Network types (PostgreSQL)
sub inet     { return (data_type => 'inet') }
sub cidr     { return (data_type => 'cidr') }
sub macaddr  { return (data_type => 'macaddr') }
sub macaddr8 { return (data_type => 'macaddr8') }

# Full-text search (PostgreSQL)
sub tsvector { return (data_type => 'tsvector') }
sub tsquery  { return (data_type => 'tsquery') }

# Geometric types (PostgreSQL)
sub point   { return (data_type => 'point') }
sub line    { return (data_type => 'line') }
sub lseg    { return (data_type => 'lseg') }
sub box     { return (data_type => 'box') }
sub path    { return (data_type => 'path') }
sub polygon { return (data_type => 'polygon') }
sub circle  { return (data_type => 'circle') }

# Range types (PostgreSQL)
sub int4range  { return (data_type => 'int4range') }
sub int8range  { return (data_type => 'int8range') }
sub numrange   { return (data_type => 'numrange') }
sub tsrange    { return (data_type => 'tsrange') }
sub tstzrange  { return (data_type => 'tstzrange') }
sub daterange  { return (data_type => 'daterange') }

# --- Keys / Constraints ---

sub primary_key {
  my (@cols) = @_;
  my $class = _caller_class();
  $class->set_primary_key(@cols);
}

sub unique {
  my @args = @_;
  my $class = _caller_class();

  if (@args == 1 && ref $args[0] eq 'ARRAY') {
    # unique \@cols — anonymous unique constraint
    $class->add_unique_constraint($args[0]);
  }
  elsif (@args == 2 && !ref $args[0] && ref $args[1] eq 'ARRAY') {
    # unique $name => \@cols
    $class->add_unique_constraint($args[0] => $args[1]);
  }
  else {
    # Pass through
    $class->add_unique_constraint(@args);
  }
}

# --- Relationships ---

sub belongs_to {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->belongs_to($name, $related, @rest);
}

sub has_one {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_one($name, $related, @rest);
}

sub has_many {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_many($name, $related, @rest);
}

sub might_have {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->might_have($name, $related, @rest);
}

sub many_to_many {
  my ($name, $link, $foreign, @rest) = @_;
  my $class = _caller_class();
  $class->many_to_many($name, $link, $foreign, @rest);
}

# rel_one: belongs_to with LEFT JOIN (nullable FK convenience)
sub rel_one {
  my ($name, $related, $cond, @rest) = @_;
  my $class = _caller_class();
  my %attrs;
  %attrs = %{pop @rest} if @rest && ref $rest[-1] eq 'HASH';
  $attrs{join_type} = 'left';
  $class->belongs_to($name, $related, $cond, \%attrs);
}

# rel_many: has_many (already LEFT JOIN by default, but explicit)
sub rel_many {
  my ($name, $related, @rest) = @_;
  my $class = _caller_class();
  $class->has_many($name, $related, @rest);
}

# --- Cascade helpers ---

sub ddl_cascade {
  return (
    on_delete => 'CASCADE',
    on_update => 'CASCADE',
  );
}

sub dbic_cascade {
  return (
    cascade_delete => 1,
    cascade_copy   => 1,
  );
}

# --- Views ---

sub view {
  my ($name, $sql, %opts) = @_;
  my $class = _caller_class();

  $class->table_class('DBIO::ResultSource::View')
    unless $class->table_class->isa('DBIO::ResultSource::View');

  require DBIO::ResultSource::View;
  $class->table($name);
  $class->result_source_instance->view_definition($sql);

  if ($opts{depends_on}) {
    $class->result_source_instance->deploy_depends_on(
      ref $opts{depends_on} ? $opts{depends_on} : [$opts{depends_on}]
    );
  }
}

# --- Indexes ---

sub idx {
  my ($name, $fields, %options) = @_;
  my $class = _caller_class();

  my $sqlt_info = $class->result_source_instance->{sqlt_deploy_callback}
    ? $class->result_source_instance->sqlt_deploy_callback
    : undef;

  # Store index info in sqlt_deploy_hook via source extra
  my $source = $class->result_source_instance;
  my $indexes = $source->{_cake_indexes} ||= [];
  push @$indexes, {
    name   => $name,
    fields => $fields,
    %options,
  };

  # Install or update the sqlt_deploy_hook
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
          (exists $idx->{type} ? (type => $idx->{type}) : ()),
        );
      }
    };
  }
}

1;

__END__

=head1 SYNOPSIS

  package MyApp::Schema::Result::Artist;
  use DBIO::Cake;

  table 'artists';

  col id     => integer, auto_inc;
  col name   => varchar(100);
  col bio    => text, null;
  col active => boolean, default(1);

  primary_key 'id';
  unique artist_name => ['name'];

  has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';

  1;

=head1 DESCRIPTION

DBIO::Cake provides a clean, DDL-like DSL for defining DBIO result classes.
Instead of calling class methods with hashref arguments, you declare your
schema using concise function calls that read like a table definition.

When you C<use DBIO::Cake>, it automatically:

=over 4

=item * Enables C<strict> and C<warnings>

=item * Sets the calling class to inherit from L<DBIO::Core>

=item * Exports all DSL functions into the calling package

=item * Cleans up exported symbols after the scope ends (via L<namespace::clean>)

=back

=head1 IMPORT OPTIONS

  use DBIO::Cake;                            # defaults
  use DBIO::Cake -inflate_datetime;          # load InflateColumn::DateTime
  use DBIO::Cake -inflate_json;              # auto-inflate json/jsonb columns
  use DBIO::Cake -retrieve_defaults;         # set retrieve_on_insert for columns with defaults
  use DBIO::Cake -no_autoclean;              # don't clean up symbols

Multiple options can be combined:

  use DBIO::Cake -inflate_datetime, -inflate_json;

=head1 COLUMN TYPES

All type functions return flat key-value lists suitable for passing to C<col>.

=head2 Integer types

C<integer>, C<tinyint>, C<smallint>, C<bigint>

=head2 Numeric types

C<numeric($precision, $scale)>, C<decimal($precision, $scale)>

=head2 Floating point types

C<real> (alias: C<float4>), C<double> (alias: C<float8>), C<float($bits)>

=head2 String types

C<char($size)>, C<varchar($size)>

=head2 Text types

C<text>, C<tinytext>, C<mediumtext>, C<longtext>

=head2 Binary types

C<blob>, C<tinyblob>, C<mediumblob>, C<longblob>, C<bytea>

=head2 Boolean

C<boolean> (alias: C<bool>)

=head2 Date/Time types

C<date>, C<datetime($tz)>, C<timestamp($tz)>

=head2 Other types

C<enum(@values)>, C<uuid>, C<json>, C<jsonb>, C<array($type)>

=head1 COLUMN MODIFIERS

=head2 null

Marks the column as nullable (C<is_nullable =E<gt> 1>).

=head2 auto_inc

Marks the column as auto-increment (C<is_auto_increment =E<gt> 1>).

=head2 fk

Marks the column as a foreign key (C<is_foreign_key =E<gt> 1>).

=head2 default($value)

Sets the default value (C<default_value =E<gt> $value>).

=head1 TABLE AND CONSTRAINT FUNCTIONS

=head2 table

  table 'my_table';

Sets the table name for this result class.

=head2 primary_key

  primary_key 'id';
  primary_key 'artist_id', 'cd_id';

Sets the primary key column(s).

=head2 unique

  unique \@cols;
  unique $name => \@cols;

Adds a unique constraint.

=head1 RELATIONSHIP FUNCTIONS

=head2 belongs_to

  belongs_to author => 'MyApp::Schema::Result::Author', 'author_id';

=head2 has_one

  has_one isbn => 'MyApp::Schema::Result::ISBN', 'book_id';

=head2 has_many

  has_many books => 'MyApp::Schema::Result::Book', 'author_id';

=head2 might_have

  might_have pseudonym => 'MyApp::Schema::Result::Pseudonym', 'author_id';

=head2 many_to_many

  many_to_many roles => 'actor_roles', 'role';

=head2 rel_one

Like C<belongs_to> but forces C<join_type =E<gt> 'left'>.

=head2 rel_many

Alias for C<has_many>.

=head1 CASCADE HELPERS

=head2 ddl_cascade

Returns C<on_delete =E<gt> 'CASCADE', on_update =E<gt> 'CASCADE'> for use in
relationship attribute hashes.

=head2 dbic_cascade

Returns C<cascade_delete =E<gt> 1, cascade_copy =E<gt> 1>.

=head1 VIEW SUPPORT

=head2 view

  view 'my_view', 'SELECT * FROM artists WHERE active = 1';

Declares a view-based result source.

=head1 INDEX SUPPORT

=head2 idx

  idx name_idx => ['name'];
  idx composite_idx => ['last_name', 'first_name'], type => 'unique';

Declares an index to be created during deployment via C<sqlt_deploy_hook>.

=head1 SEE ALSO

L<DBIO::Core>, L<DBIO::ResultSource>

=cut
