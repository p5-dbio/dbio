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

done_testing;
