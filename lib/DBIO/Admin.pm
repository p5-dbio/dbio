package DBIO::Admin;
# ABSTRACT: Administration object for schemas

use strict;
use warnings;

use JSON::MaybeXS ();
use Try::Tiny;
use Scalar::Util 'blessed';

=head1 SYNOPSIS

  $ dbioadmin --help

  $ dbioadmin --schema=MyApp::Schema \
    --connect='["dbi:SQLite:my.db", "", ""]' \
    --deploy

  $ dbioadmin --schema=MyApp::Schema --class=Employee \
    --connect='["dbi:SQLite:my.db", "", ""]' \
    --op=update --set='{ "name": "New_Employee" }'

  use DBIO::Admin;

  # ddl manipulation
  my $admin = DBIO::Admin->new(
    schema_class=> 'MY::Schema',
    sql_dir=> $sql_dir,
    connect_info => { dsn => $dsn, user => $user, password => $pass },
  );

  # create SQLite sql
  $admin->create('SQLite');

  # create SQL diff for an upgrade
  $admin->create('SQLite', {} , "1.0");

  # upgrade a database
  $admin->upgrade();

  # install a version for an unversioned schema
  $admin->install("3.0");

=head1 REQUIREMENTS

The Admin interface has additional requirements not currently part of
L<DBIO>. See L<DBIO::Optional::Dependencies> for more details.

=head1 ATTRIBUTES

=head2 schema_class

the class of the schema to load

=cut

=head2 schema

A pre-connected schema object can be provided for manipulation

=cut

=head2 resultset

a resultset from the schema to operate on

=cut

=head2 where

a hash ref or json string to be used for identifying data to manipulate

=cut

=head2 set

a hash ref or json string to be used for inserting or updating data

=cut

=head2 attrs

a hash ref or json string to be used for passing additional info to the ->search call

=cut

=head2 connect_info

connect_info the arguments to provide to the connect call of the schema_class

=cut

=head2 config_file

config_file provide a config_file to read connect_info from, if this is provided
config_stanze should also be provided to locate where the connect_info is in the config
The config file should be in a format readable by Config::Any.

=cut

=head2 config_stanza

config_stanza for use with config_file should be a '::' delimited 'path' to the connection information
designed for use with catalyst config files

=cut

=head2 config

Instead of loading from a file the configuration can be provided directly as a hash ref.  Please note
config_stanza will still be required.

=cut

=head2 sql_dir

The location where sql ddl files should be created or found for an upgrade.

=cut

=head2 sql_type

The type of sql dialect to use for creating sql files from schema

=cut

=head2 version

Used for install, the version which will be 'installed' in the schema

=cut

=head2 preversion

Previous version of the schema to create an upgrade diff for, the full sql for that version of the sql must be in the sql_dir

=cut

=head2 force

Try and force certain operations.

=cut

=head2 quiet

Be less verbose about actions

=cut

=head2 trace

Toggle DBIO debug output

=cut

sub new {
  my ($class, %args) = @_;

  my $self = bless {}, $class;

  # Simple string/scalar attributes
  for my $attr (qw(schema_class resultset config_stanza sql_dir sql_type
                    version preversion config_file)) {
    $self->{$attr} = $args{$attr} if exists $args{$attr};
  }

  # Boolean attributes
  for my $attr (qw(force quiet _confirm)) {
    $self->{$attr} = $args{$attr} ? 1 : 0 if exists $args{$attr};
  }

  # Coercible hash attributes (accept JSON strings)
  for my $attr (qw(where set attrs)) {
    if (exists $args{$attr}) {
      $self->{$attr} = _coerce_hashref($args{$attr});
    }
  }

  # connect_info: accept JSON string, hashref, or arrayref
  if (exists $args{connect_info}) {
    $self->{connect_info} = _coerce_connect_info($args{connect_info});
  }

  # config: accept JSON string or hashref
  if (exists $args{config}) {
    $self->{config} = _coerce_hashref($args{config});
  }

  # schema: accept a pre-connected schema object
  if (exists $args{schema}) {
    $self->{schema} = $args{schema};
  }

  # Load the schema class if provided
  if ($self->{schema_class}) {
    my $schema_class = $self->{schema_class};
    (my $file = "$schema_class.pm") =~ s{::}{/}g;
    require $file;
  }

  # Set trace if requested
  if ($args{trace}) {
    $self->{trace} = 1;
  }

  return $self;
}

# Read-only accessors
for my $attr (qw(schema_class config_stanza sql_dir sql_type config_file)) {
  no strict 'refs';
  *{$attr} = sub { $_[0]->{$attr} };
}

# Read-write accessors
for my $attr (qw(resultset version preversion force quiet)) {
  no strict 'refs';
  *{$attr} = sub {
    if (@_ > 1) {
      $_[0]->{$attr} = $_[1];
      return $_[0];
    }
    return $_[0]->{$attr};
  };
}

# Read-write accessors with JSON coercion
for my $attr (qw(where set attrs)) {
  no strict 'refs';
  *{$attr} = sub {
    if (@_ > 1) {
      $_[0]->{$attr} = _coerce_hashref($_[1]);
      return $_[0];
    }
    return $_[0]->{$attr};
  };
}

=method trace

=cut

sub trace {
  my ($self, @args) = @_;
  if (@args) {
    $self->{trace} = $args[0];
    $self->schema->storage->debug($args[0]);
    return $self;
  }
  return $self->{trace};
}

=method schema

=cut

sub schema {
  my ($self) = @_;
  $self->{schema} ||= $self->_build_schema;
  return $self->{schema};
}

=method _build_schema

=cut

sub _build_schema {
  my ($self)  = @_;

  $self->connect_info->[3]{ignore_version} = 1;
  return $self->schema_class->connect(@{$self->connect_info});
}

=method connect_info

=cut

sub connect_info {
  my ($self) = @_;
  $self->{connect_info} ||= $self->_build_connect_info;
  return $self->{connect_info};
}

=method _build_connect_info

=cut

sub _build_connect_info {
  my ($self) = @_;
  return $self->_find_stanza($self->config, $self->config_stanza);
}

=method config

=cut

sub config {
  my ($self) = @_;
  $self->{config} ||= $self->_build_config;
  return $self->{config};
}

=method _build_config

=cut

sub _build_config {
  my ($self) = @_;

  try { require Config::Any }
    catch { die ("Config::Any is required to parse the config file.\n") };

  my $cfg = Config::Any->load_files ( {files => [$self->config_file], use_ext =>1, flatten_to_hash=>1});

  # just grab the config from the config file
  $cfg = $cfg->{$self->config_file};
  return $cfg;
}


=head1 METHODS

=head2 create

=over 4

=item Arguments: $sqlt_type, \%sqlt_args, $preversion

=back

C<create> will generate sql for the supplied schema_class in sql_dir. The
flavour of sql to generate can be controlled by supplying a sqlt_type which
should be a L<SQL::Translator> name.

Arguments for L<SQL::Translator> can be supplied in the sqlt_args hashref.

Optional preversion can be supplied to generate a diff to be used by upgrade.

=cut

=method create

=cut

sub create {
  my ($self, $sqlt_type, $sqlt_args, $preversion) = @_;

  $preversion ||= $self->preversion();
  $sqlt_type ||= $self->sql_type();

  my $schema = $self->schema();
  # create the dir if does not exist
  if ( ! -d $self->sql_dir) {
    require File::Path;
    File::Path::mkpath($self->sql_dir);
  }

  $schema->create_ddl_dir( $sqlt_type, (defined $schema->schema_version ? $schema->schema_version : ""), $self->sql_dir, $preversion, $sqlt_args );
}


=head2 upgrade

=over 4

=item Arguments: <none>

=back

upgrade will attempt to upgrade the connected database to the same version as the schema_class.
B<MAKE SURE YOU BACKUP YOUR DB FIRST>

=cut

=method upgrade

=cut

sub upgrade {
  my ($self) = @_;
  my $schema = $self->schema();

  if (!$schema->get_db_version()) {
    # schema is unversioned
    $schema->throw_exception ("Could not determin current schema version, please either install() or deploy().\n");
  } else {
    $schema->upgrade_directory ($self->sql_dir) if $self->sql_dir;  # this will override whatever default the schema has
    my $ret = $schema->upgrade();
    return $ret;
  }
}


=head2 install

=over 4

=item Arguments: $version

=back

install is here to help when you want to move to L<DBIO::Schema::Versioned> and have an existing
database.  install will take a version and add the version tracking tables and 'install' the version.  No
further ddl modification takes place.  Setting the force attribute to a true value will allow overriding of
already versioned databases.

=cut

=method install

=cut

sub install {
  my ($self, $version) = @_;

  my $schema = $self->schema();
  $version ||= $self->version();
  if (!$schema->get_db_version() ) {
    # schema is unversioned
    print "Going to install schema version\n" if (!$self->quiet);
    my $ret = $schema->install($version);
    print "return is $ret\n" if (!$self->quiet);
  }
  elsif ($schema->get_db_version() and $self->force ) {
    warn "Forcing install may not be a good idea\n";
    if($self->_confirm() ) {
      $self->schema->_set_db_version({ version => $version});
    }
  }
  else {
    $schema->throw_exception ("Schema already has a version. Try upgrade instead.\n");
  }

}


=head2 deploy

=over 4

=item Arguments: $args

=back

deploy will create the schema at the connected database.  C<$args> are passed straight to
L<DBIO::Schema/deploy>.

=cut

=method deploy

=cut

sub deploy {
  my ($self, $args) = @_;
  my $schema = $self->schema();
  $schema->deploy( $args, $self->sql_dir );
}

=head2 insert

=over 4

=item Arguments: $rs, $set

=back

insert takes the name of a resultset from the schema_class and a hashref of data to insert
into that resultset

=cut

=method insert

=cut

sub insert {
  my ($self, $rs, $set) = @_;

  $rs ||= $self->resultset();
  $set ||= $self->set();
  my $resultset = $self->schema->resultset($rs);
  my $obj = $resultset->new_result($set)->insert;
  print ''.ref($resultset).' ID: '.join(',',$obj->id())."\n" if (!$self->quiet);
}


=head2 update

=over 4

=item Arguments: $rs, $set, $where

=back

update takes the name of a resultset from the schema_class, a hashref of data to update and
a where hash used to form the search for the rows to update.

=cut

=method update

=cut

sub update {
  my ($self, $rs, $set, $where) = @_;

  $rs ||= $self->resultset();
  $where ||= $self->where();
  $set ||= $self->set();
  my $resultset = $self->schema->resultset($rs);
  $resultset = $resultset->search( ($where||{}) );

  my $count = $resultset->count();
  print "This action will modify $count ".ref($resultset)." records.\n" if (!$self->quiet);

  if ( $self->force || $self->_confirm() ) {
    $resultset->update_all( $set );
  }
}


=head2 delete

=over 4

=item Arguments: $rs, $where, $attrs

=back

delete takes the name of a resultset from the schema_class, a where hashref and a attrs to pass to ->search.
The found data is deleted and cannot be recovered.

=cut

=method delete

=cut

sub delete {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset();
  $where ||= $self->where();
  $attrs ||= $self->attrs();
  my $resultset = $self->schema->resultset($rs);
  $resultset = $resultset->search( ($where||{}), ($attrs||()) );

  my $count = $resultset->count();
  print "This action will delete $count ".ref($resultset)." records.\n" if (!$self->quiet);

  if ( $self->force || $self->_confirm() ) {
    $resultset->delete_all();
  }
}


=head2 select

=over 4

=item Arguments: $rs, $where, $attrs

=back

select takes the name of a resultset from the schema_class, a where hashref and a attrs to pass to ->search.
The found data is returned in a array ref where the first row will be the columns list.

=cut

=method select

=cut

sub select {
  my ($self, $rs, $where, $attrs) = @_;

  $rs ||= $self->resultset();
  $where ||= $self->where();
  $attrs ||= $self->attrs();
  my $resultset = $self->schema->resultset($rs);
  $resultset = $resultset->search( ($where||{}), ($attrs||()) );

  my @data;
  my @columns = $resultset->result_source->columns();
  push @data, [@columns];#

  while (my $row = $resultset->next()) {
    my @fields;
    foreach my $column (@columns) {
      push( @fields, $row->get_column($column) );
    }
    push @data, [@fields];
  }

  return \@data;
}

=method _confirm

=cut

sub _confirm {
  my ($self) = @_;

  # mainly here for testing
  return 1 if $self->{_confirm};

  print "Are you sure you want to do this? (type YES to confirm) \n";
  my $response = <STDIN>;

  return ($response=~/^YES/);
}

=method _find_stanza

=cut

sub _find_stanza {
  my ($self, $cfg, $stanza) = @_;
  my @path = split /::/, $stanza;
  while (my $path = shift @path) {
    if (exists $cfg->{$path}) {
      $cfg = $cfg->{$path};
    }
    else {
      die ("Could not find $stanza in config, $path does not seem to exist.\n");
    }
  }
  $cfg = $cfg->{connect_info} if exists $cfg->{connect_info};
  return $cfg;
}

# Private helper: coerce a value to a hashref (from JSON string or passthrough)
sub _coerce_hashref {
  my ($val) = @_;
  return $val if ref $val;
  return _json_to_data($val) if defined $val;
  return $val;
}

# Private helper: coerce connect_info to arrayref
sub _coerce_connect_info {
  my ($val) = @_;
  return [$val] if ref $val eq 'HASH';
  return $val if ref $val eq 'ARRAY';
  return _json_to_data($val) if defined $val;
  return $val;
}

# Private helper: decode JSON string to Perl data
sub _json_to_data {
  my ($json_str) = @_;
  my $json = eval { JSON::MaybeXS->new(
    allow_barekey     => 1,
    allow_singlequote => 1,
    relaxed           => 1,
  ) } || JSON::MaybeXS->new(relaxed => 1);
  return $json->decode($json_str);
}

=head1 FURTHER QUESTIONS?

Check the list of L<additional DBIC resources|DBIO/GETTING HELP/SUPPORT>.

=head1 COPYRIGHT AND LICENSE

This module is free software L<copyright|DBIO/COPYRIGHT AND LICENSE>
by the L<DBIO (DBIC) authors|DBIO/AUTHORS>. You can
redistribute it and/or modify it under the same terms as the
L<DBIO library|DBIO/COPYRIGHT AND LICENSE>.

=cut

1;
