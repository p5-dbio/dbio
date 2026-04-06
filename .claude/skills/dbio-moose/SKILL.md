---
name: dbio-moose
description: "DBIO::Moose bridge — Moose attributes in DBIO Result classes, Schema classes, and ResultSet classes. Combinations with Cake and Candy."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DBIO::Moose bridges Moose and DBIO so that Moose attributes (with full type constraints, roles, etc.) and DBIO columns coexist. Optional — Moose and MooseX::NonMoose are `suggests` in cpanfile.

## What `use DBIO::Moose` Does

1. Activates `use Moose` and `use MooseX::NonMoose` in the calling package
2. Sets `DBIO::Core` as the base class via `extends`
3. Installs `FOREIGNBUILDARGS` via `$caller->meta->add_method` (not a glob) that filters Moose attrs before calling `DBIO::Row::new`

### Why `add_method` instead of a glob?

MooseX::NonMoose installs a default pass-through FOREIGNBUILDARGS. If we override it via glob (`*{...} = \&sub`), Moose's metaclass doesn't know about it. When `make_immutable` inlines the constructor, it reads from the metaclass and uses the MooseX::NonMoose pass-through — which doesn't filter. Using `$meta->add_method` properly registers our version so `make_immutable` picks it up.

## The Two Construction Paths

| Path | When | Moose `new()` runs? |
|------|------|---------------------|
| `new()` | `create()`, `new_result()` | **Yes** — MooseX::NonMoose constructor runs, calls FOREIGNBUILDARGS, forwards filtered args to `DBIO::Row::new` |
| `inflate_result()` | `find`, `search`, `all` — any DB fetch | **No** — blesses a hash directly, bypasses `new()` entirely |

## The Lazy Requirement

Moose attributes with defaults **must** be `lazy => 1`. Non-lazy defaults are set during `new()`, which doesn't run for `inflate_result` rows.

```perl
# WRONG — default is undef on DB-fetched rows
has score => (is => 'rw', isa => 'Int', default => 0);

# CORRECT — default computed on first access
has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);

# Also correct — lazy builder
has display_name => (
  is      => 'ro',
  isa     => 'Str',
  lazy    => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }
```

## Result Class — Plain (Vanilla columns)

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moose;

__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type => 'integer', is_auto_increment => 1 },
  name => { data_type => 'varchar', size => 100 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');

has display_name => (
  is => 'ro', isa => 'Str', lazy => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);

__PACKAGE__->meta->make_immutable;
1;
```

## Result Class — with Cake

Load `DBIO::Moose` FIRST, then `DBIO::Cake`:

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moose;
use DBIO::Cake;

table 'artist';

col id   => integer auto_inc;
col name => varchar(100);

primary_key 'id';

has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';

has display_name => (
  is => 'ro', isa => 'Str', lazy => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

__PACKAGE__->meta->make_immutable;
1;
```

## Result Class — with Candy

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moose;
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

has display_name => (
  is => 'ro', isa => 'Str', lazy => 1,
  builder => '_build_display_name',
);
sub _build_display_name { 'Artist: ' . $_[0]->name }

__PACKAGE__->meta->make_immutable;
1;
```

## make_immutable

**Always call `__PACKAGE__->meta->make_immutable`** at the end of every Moose Result class. It is safe:

- `inflate_result` never calls `new()` — make_immutable doesn't affect the DB-fetch path
- The inlined `new()` preserves the FOREIGNBUILDARGS call (because we registered via `add_method`)

Call it after all `has`, `with`, `before`/`after`/`around` declarations.

## Moose Roles

Moose roles work normally. DBIO column accessors satisfy `requires`:

```perl
package MyApp::Role::Displayable;
use Moose::Role;
requires 'name';
has display_name => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build_display_name');
sub _build_display_name { 'Display: ' . $_[0]->name }

# In the Result class:
with 'MyApp::Role::Displayable';
```

## Type Constraints

Moose type constraints work on both construction paths:
- On `new()`: constraint fires during attribute initialization
- On `inflate_result` + mutation: constraint fires on `$row->score('bad')`

```perl
has score => (is => 'rw', isa => 'Int', lazy => 1, default => 0);
$row->score('not-an-int');  # dies: Validation failed
```

## Schema Class with Moose

```perl
package MyApp::Schema;

use Moose;
extends 'DBIO::Schema';

has verbose => (is => 'rw', isa => 'Bool', lazy => 1, default => 0);

__PACKAGE__->load_namespaces;

__PACKAGE__->meta->make_immutable;
1;
```

## Custom ResultSet with Moose

MooseX::NonMoose's default pass-through FOREIGNBUILDARGS is correct for ResultSets — no filtering needed:

```perl
package MyApp::Schema::ResultSet::Artist;

use Moose;
use MooseX::NonMoose;
extends 'DBIO::ResultSet';

has default_limit => (is => 'rw', isa => 'Int', lazy => 1, default => 100);

sub active  { $_[0]->search({ active => 1 }) }
sub by_name { $_[0]->search({ name => $_[1] }) }

__PACKAGE__->meta->make_immutable;
1;
```

Set on the Result class:
```perl
__PACKAGE__->resultset_class('MyApp::Schema::ResultSet::Artist');
```

## Test Schemas

Shared test schemas in `DBIO::Test::Schema::*`:

| Schema | Style |
|--------|-------|
| `DBIO::Test::Schema::Moose` | Moose + Vanilla (add_columns) |
| `DBIO::Test::Schema::MooseSugar` | Moose + Cake DDL |

Each has Artist + CD, `has_many`/`belongs_to`, one custom ResultSet (Artist), one default (CD). Both schemas and all Result/ResultSet classes use `make_immutable`.

Core tests (`dbio/t/moose.t`, `dbio/t/moose-sugar.t`) use `DBIO::Test::Storage`. Driver tests (`dbio-sqlite/t/moose-moose.t`, `dbio-sqlite/t/moose-sugar.t`) test the real DB round-trip.
