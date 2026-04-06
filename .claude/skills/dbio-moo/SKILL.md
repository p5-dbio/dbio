---
name: dbio-moo
description: "DBIO::Moo bridge — Moo attributes in DBIO Result classes, Schema classes, and ResultSet classes. Combinations with Cake and Candy."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO::Moo bridges Moo and DBIO so that Moo attributes and DBIO columns coexist without conflict. Optional — Moo is listed as `suggests` in cpanfile.

## What `use DBIO::Moo` Does

1. Activates `use Moo` in the calling package
2. Sets `DBIO::Core` as the base class via `extends`
3. Installs `FOREIGNBUILDARGS` that filters constructor arguments — only DBIO-known keys (columns, relationships, `-` prefixed internals) are forwarded to `DBIO::Row::new`

Without FOREIGNBUILDARGS, `DBIO::Row::new` calls `store_column` for every key and dies on unknown columns (e.g. Moo attrs).

## The Two Construction Paths

| Path | When | Moo `new()` runs? |
|------|------|-------------------|
| `new()` | `create()`, `new_result()` | **Yes** — Moo constructor runs, calls FOREIGNBUILDARGS, forwards filtered args to `DBIO::Row::new` |
| `inflate_result()` | `find`, `search`, `all` — any DB fetch | **No** — blesses a hash directly, bypasses `new()` entirely |

## The Lazy Requirement

Moo attributes with defaults **must** be `lazy => 1`. Non-lazy defaults are set during `new()`, which doesn't run for `inflate_result` rows.

```perl
# WRONG — default is undef on DB-fetched rows
has score => (is => 'rw', default => sub { 0 });

# CORRECT — default computed on first access
has score => (is => 'rw', lazy => 1, default => sub { 0 });

# Also correct — is => 'lazy' is inherently lazy
has display_name => (is => 'lazy');
sub _build_display_name { 'Artist: ' . $_[0]->name }
```

## Result Class — Plain (Vanilla columns)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 100 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');

has display_name => (is => 'lazy');
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => (is => 'rw', lazy => 1, default => sub { 0 });

1;
```

## Result Class — with Cake

Load `DBIO::Moo` FIRST, then `DBIO::Cake` (Cake keywords need DBIO::Core in the inheritance chain):

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;
use DBIO::Cake;

table 'artist';

col id   => integer auto_inc;
col name => varchar(100);

primary_key 'id';

has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';

has display_name => (is => 'lazy');
sub _build_display_name { 'Artist: ' . $_[0]->name }

1;
```

## Result Class — with Candy

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;
use DBIO::Candy;

table 'artist';

column id => {
  data_type         => 'integer',
  is_auto_increment => 1,
};

column name => {
  data_type => 'varchar',
  size      => 100,
};

primary_key 'id';

has display_name => (is => 'lazy');
sub _build_display_name { 'Artist: ' . $_[0]->name }

1;
```

## Schema Class with Moo

Schema classes can also use Moo for schema-level attributes:

```perl
package MyApp::Schema;

use Moo;
extends 'DBIO::Schema';

has verbose => (is => 'rw', lazy => 1, default => sub { 0 });

__PACKAGE__->load_namespaces;

1;
```

## Custom ResultSet with Moo

FOREIGNBUILDARGS is a simple pass-through — `DBIO::ResultSet::new` takes positional args and doesn't reject unknown keys:

```perl
package MyApp::Schema::ResultSet::Artist;

use Moo;
extends 'DBIO::ResultSet';

# Pass constructor args through to DBIO::ResultSet::new unchanged
sub FOREIGNBUILDARGS { my ($class, @args) = @_; return @args }

has default_limit => (is => 'rw', lazy => 1, default => sub { 100 });

sub active  { $_[0]->search({ active => 1 }) }
sub by_name { $_[0]->search({ name => $_[1] }) }

1;
```

Set on the Result class:
```perl
__PACKAGE__->resultset_class('MyApp::Schema::ResultSet::Artist');
```

## Unknown Keys Are Silently Dropped

FOREIGNBUILDARGS filters out everything that isn't a column, relationship, or `-` prefixed key. It cannot distinguish a Moo attr from a typo — both are dropped before `DBIO::Row::new` sees them.

## Test Schemas

Shared test schemas in `DBIO::Test::Schema::*`:

| Schema | Style |
|--------|-------|
| `DBIO::Test::Schema::Moo` | Moo + Vanilla (add_columns) |
| `DBIO::Test::Schema::MooCake` | Moo + Cake DDL |

Each has Artist + CD, `has_many`/`belongs_to`, one custom ResultSet (Artist), one default (CD).

Core tests (`dbio/t/moo.t`, `dbio/t/moo-cake.t`) use `DBIO::Test::Storage` (fake, no DB). Driver tests (`dbio-sqlite/t/moo-cake.t`) test the real DB round-trip.
