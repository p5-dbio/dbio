use strict;
use warnings;
use Test::More;

use lib 't/lib';
use DBIO::Compat::DBIxClass;

# Test: Hook is installed at the front of @INC
ok(ref $INC[0] eq 'CODE', '@INC hook installed as first entry');

# Test: DBIO::Core is available (loaded via DBIO::Schema dependency chain)
require DBIO::Core;
ok(DBIO::Core->can('table'), 'DBIO::Core->can(table)');

# Test: require DBIx::Class::Core works via hook
require DBIx::Class::Core;
ok(exists $INC{'DBIx/Class/Core.pm'}, 'DBIx/Class/Core.pm in %INC after require');
ok(exists $INC{'DBIO/Core.pm'}, 'DBIO/Core.pm also loaded');

# Test: Method resolution works via stash alias
ok(DBIx::Class::Core->can('table'), 'DBIx::Class::Core->can(table)');
ok(DBIx::Class::Core->can('add_columns'), 'DBIx::Class::Core->can(add_columns)');
ok(DBIx::Class::Core->can('set_primary_key'), 'DBIx::Class::Core->can(set_primary_key)');
ok(DBIx::Class::Core->can('load_components'), 'DBIx::Class::Core->can(load_components)');
ok(DBIx::Class::Core->can('has_many'), 'DBIx::Class::Core->can(has_many)');
ok(DBIx::Class::Core->can('belongs_to'), 'DBIx::Class::Core->can(belongs_to)');

# Test: The can() references are the same as DBIO::Core's
is(DBIx::Class::Core->can('table'), DBIO::Core->can('table'),
  'DBIx::Class::Core->can(table) returns same coderef as DBIO::Core');

# Test: require DBIx::Class works via hook (the main module)
require DBIx::Class;
ok(exists $INC{'DBIx/Class.pm'}, 'DBIx/Class.pm in %INC');
ok(DBIx::Class->can('component_base_class'), 'DBIx::Class->can(component_base_class)');

# Test: require DBIx::Class::Schema works via hook
require DBIx::Class::Schema;
ok(exists $INC{'DBIx/Class/Schema.pm'}, 'DBIx/Class/Schema.pm in %INC');
ok(DBIx::Class::Schema->can('connect'), 'DBIx::Class::Schema->can(connect)');
ok(DBIx::Class::Schema->can('resultset'), 'DBIx::Class::Schema->can(resultset)');

# Test: isa() patch works
ok(DBIO::Core->isa('DBIx::Class::Core'), 'DBIO::Core->isa(DBIx::Class::Core)');
ok(DBIO::Core->isa('DBIx::Class'), 'DBIO::Core->isa(DBIx::Class)');
ok(DBIO->isa('DBIx::Class'), 'DBIO->isa(DBIx::Class)');

# Test: isa() for non-DBIO classes still returns false
ok(!DBIO::Core->isa('Foo::Bar'), 'DBIO::Core->isa(Foo::Bar) is false');
ok(!DBIO->isa('DBIx::Class::Core'), 'DBIO->isa(DBIx::Class::Core) is false (DBIO is not Core)');

# Test: Hook ignores non-DBIx::Class requests
{
  local $@;
  eval { require Foo::Bar::Baz };
  ok($@, 'Hook does not intercept non-DBIx::Class modules');
}

# Test: Hook ignores DBIx::Class modules without DBIO equivalents
{
  local $@;
  eval { require DBIx::Class::NonExistentModule };
  ok($@, 'Hook does not intercept DBIx::Class modules without DBIO equivalent');
}

# Test: Second require is a no-op
{
  my $old_inc = $INC{'DBIx/Class/Core.pm'};
  require DBIx::Class::Core;
  is($INC{'DBIx/Class/Core.pm'}, $old_inc, 'Second require is a no-op');
}

# Test: MRO includes DBIO::Core's hierarchy
{
  require mro;
  my @dbio_mro = @{mro::get_linear_isa('DBIO::Core')};
  my @dbix_mro = @{mro::get_linear_isa('DBIx::Class::Core')};
  ok(scalar @dbix_mro > 1, 'DBIx::Class::Core has a non-trivial MRO');
  is($dbix_mro[0], 'DBIx::Class::Core', 'MRO starts with DBIx::Class::Core');
  is($dbix_mro[1], 'DBIO::Core', 'MRO second entry is DBIO::Core');
  # The rest should match DBIO::Core's MRO (minus DBIO::Core itself)
  is_deeply([@dbix_mro[1..$#dbix_mro]], \@dbio_mro,
    'DBIx::Class::Core MRO tail matches full DBIO::Core MRO');
}

done_testing;
