use strict;
use warnings;
use Test::More;
use Test::Exception;

# --- Role auto-detection: ::Result:: -> Core ---

{
  package TestPragma::Schema::Result::Artist;
  use DBIO;

  __PACKAGE__->table('artist');
  __PACKAGE__->add_columns(qw/id name/);
  __PACKAGE__->set_primary_key('id');
}

ok(TestPragma::Schema::Result::Artist->isa('DBIO::Core'),
  '::Result:: package auto-detects Core role');
is(TestPragma::Schema::Result::Artist->table, 'artist',
  'DBIO::Core methods work on auto-Core class');

# --- Role auto-detection: ::ResultSet:: -> ResultSet ---

{
  package TestPragma::Schema::ResultSet::Artist;
  use DBIO;
}

ok(TestPragma::Schema::ResultSet::Artist->isa('DBIO::ResultSet'),
  '::ResultSet:: package auto-detects ResultSet role');

# --- Explicit role: Schema ---

{
  package TestPragma::Schema;
  use DBIO 'Schema';
}

ok(TestPragma::Schema->isa('DBIO::Schema'),
  "use DBIO 'Schema' installs DBIO::Schema as base");

# --- Explicit override: Core in a ::ResultSet:: package ---

{
  package TestPragma::Schema::ResultSet::Overriden;
  use DBIO 'Core';
}

ok(TestPragma::Schema::ResultSet::Overriden->isa('DBIO::Core'),
  'explicit role overrides package-name heuristic');
ok(!TestPragma::Schema::ResultSet::Overriden->isa('DBIO::ResultSet'),
  'overridden class does not pick up auto-detected role');

# --- Ambivalent namespace defaults to Core ---

{
  package TestPragma::Random::Thing;
  use DBIO;
}

ok(TestPragma::Random::Thing->isa('DBIO::Core'),
  'ambivalent package name defaults to Core role');

# --- Idempotency: use DBIO twice -> no duplicate @ISA entries ---

{
  package TestPragma::Schema::Result::Twice;
  use DBIO;
  use DBIO;
}

my @isa = do { no strict 'refs'; @{'TestPragma::Schema::Result::Twice::ISA'} };
my @core_hits = grep { $_ eq 'DBIO::Core' } @isa;
is(scalar(@core_hits), 1,
  'double use DBIO results in only one DBIO::Core in @ISA');

# --- Coexistence: use base 'DBIO::Core' + use DBIO does not double ---

{
  package TestPragma::Schema::Result::Coexist;
  use base 'DBIO::Core';
  use DBIO;
}

my @isa2 = do { no strict 'refs'; @{'TestPragma::Schema::Result::Coexist::ISA'} };
my @core_hits2 = grep { $_ eq 'DBIO::Core' } @isa2;
is(scalar(@core_hits2), 1,
  'use base + use DBIO coexist without duplicate DBIO::Core in @ISA');

# --- Unknown role dies with helpful message ---

throws_ok {
  eval q{
    package TestPragma::Broken::Role;
    use DBIO 'NonsenseRole';
  };
  die $@ if $@;
} qr/cannot load DBIO::NonsenseRole/i,
  "use DBIO 'NonsenseRole' dies with helpful error";

# --- Unknown shortcut dies with helpful message ---

throws_ok {
  eval q{
    package TestPragma::Broken::Shortcut;
    use DBIO -totally_unknown;
  };
  die $@ if $@;
} qr/unknown shortcut/i,
  'use DBIO -unknown dies with helpful error';

# --- DBIO::Base is the meta-infra parent of every internal class ---

ok(DBIO::Core->isa('DBIO::Base'),
  'DBIO::Core inherits from DBIO::Base (meta-infra split)');
ok(DBIO::Schema->isa('DBIO::Base'),
  'DBIO::Schema inherits from DBIO::Base');
ok(DBIO::ResultSet->isa('DBIO::Base'),
  'DBIO::ResultSet inherits from DBIO::Base');

# --- DBIO.pm is NOT in the MRO of anything (no leakage) ---

ok(!TestPragma::Schema::Result::Artist->isa('DBIO'),
  'result class does not inherit from DBIO.pm itself (no MRO leak)');
ok(!DBIO::Core->isa('DBIO'),
  'DBIO::Core does not inherit from DBIO.pm');

done_testing();
