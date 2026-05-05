use strict;
use warnings;
use Test::More;

{
  package Test::Introspect;
  use base 'DBIO::Introspect::Base';
  sub _build_model { return { tables => { foo => 1 } } }
}

my $intro = Test::Introspect->new(dbh => 'fake');
is $intro->dbh, 'fake', 'dbh accessor';
is_deeply $intro->model, { tables => { foo => 1 } }, 'model built lazily';
is $intro->model, $intro->model, 'model cached (same ref)';

# Abstract base must die without _build_model
{
  package Bare::Introspect;
  use base 'DBIO::Introspect::Base';
}
eval { Bare::Introspect->new(dbh => 'x')->model };
ok $@, '_build_model not overridden → dies';
like $@, qr/_build_model/, 'error mentions _build_model';

# _aggregate_by helper
{
  my @rows = (
    { table => 'users',   name => 'id'    },
    { table => 'users',   name => 'email' },
    { table => 'orders',  name => 'id'    },
  );

  my $grouped = DBIO::Introspect::Base->_aggregate_by(\@rows, 'table');

  is ref($grouped), 'HASH', '_aggregate_by returns hashref';
  is scalar @{ $grouped->{users}  }, 2, 'users has 2 rows';
  is scalar @{ $grouped->{orders} }, 1, 'orders has 1 row';
  is $grouped->{users}[0]{name}, 'id',    'first user column is id';
  is $grouped->{users}[1]{name}, 'email', 'second user column is email';
}

done_testing;
