---
name: dbio-moose
description: "DBIO::Moose bridge — Moose attributes in DBIO Result classes, Schema classes, and ResultSet classes. Combinations with Cake and Candy."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Bridge: Moose attrs (full type constraints, roles) + DBIO columns. Optional (`Moose`, `MooseX::NonMoose` are `suggests`).

## What `use DBIO::Moose` does

1. `use Moose` + `use MooseX::NonMoose` in caller
2. `extends 'DBIO::Core'`
3. Installs FOREIGNBUILDARGS via `$caller->meta->add_method` — filters Moose attrs before `DBIO::Row::new`

### Why `add_method` (not glob)

MooseX::NonMoose installs default pass-through FOREIGNBUILDARGS. Glob assignment is invisible to metaclass → `make_immutable` inlines the WRONG (unfiltered) version. `add_method` registers it properly so the inlined constructor uses ours.

## Two construction paths

| Path | Trigger | `new()` runs? |
|---|---|---|
| `new()` | `create()`, `new_result()` | yes — MooseX::NonMoose ctor → FOREIGNBUILDARGS → `DBIO::Row::new` |
| `inflate_result()` | any DB fetch | NO — blesses hash, bypasses `new()` |

## Lazy mandatory

```perl
# WRONG — undef on DB-fetched rows
has score => (is=>'rw', isa=>'Int', default=>0);
# CORRECT
has score => (is=>'rw', isa=>'Int', lazy=>1, default=>0);
has display_name => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_display_name');
sub _build_display_name { 'Artist: '.$_[0]->name }
```

## Result — Vanilla columns

```perl
use DBIO::Moose;
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type=>'integer', is_auto_increment=>1 },
  name => { data_type=>'varchar', size=>100 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');
has display_name => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_display_name');
sub _build_display_name { 'Artist: '.$_[0]->name }
__PACKAGE__->meta->make_immutable;
1;
```

## With Cake — Moose FIRST, then Cake

```perl
use DBIO::Moose;
use DBIO::Cake;
table 'artist';
col id   => integer auto_inc;
col name => varchar(100);
primary_key 'id';
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
has display_name => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_display_name');
__PACKAGE__->meta->make_immutable;
```

## With Candy

```perl
use DBIO::Moose;
use DBIO::Candy;
table 'artist';
column id   => { data_type=>'integer', is_auto_increment=>1 };
column name => { data_type=>'varchar', size=>100 };
primary_key 'id';
has display_name => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_display_name');
__PACKAGE__->meta->make_immutable;
```

## make_immutable

Always call `__PACKAGE__->meta->make_immutable` at end of every Moose Result class. Safe because:
- `inflate_result` skips `new()` entirely
- Inlined `new()` includes our FOREIGNBUILDARGS (registered via `add_method`)

Call after all `has`/`with`/`before`/`after`/`around`.

## Roles

Work normally. DBIO accessors satisfy `requires`:
```perl
package MyApp::Role::Displayable;
use Moose::Role;
requires 'name';
has display_name => (is=>'ro', isa=>'Str', lazy=>1, builder=>'_build_display_name');
# In Result: with 'MyApp::Role::Displayable';
```

## Type constraints

- `new()` path: fires during attr init
- After `inflate_result`: fires on mutation `$row->score('bad')` → dies

## Schema class

```perl
use Moose;
extends 'DBIO::Schema';
has verbose => (is=>'rw', isa=>'Bool', lazy=>1, default=>0);
__PACKAGE__->load_namespaces;
__PACKAGE__->meta->make_immutable;
```

## Custom ResultSet

MooseX::NonMoose's default pass-through is correct for ResultSet — no filtering needed:

```perl
use Moose;
use MooseX::NonMoose;
extends 'DBIO::ResultSet';
has default_limit => (is=>'rw', isa=>'Int', lazy=>1, default=>100);
sub active  { $_[0]->search({active=>1}) }
sub by_name { $_[0]->search({name=>$_[1]}) }
__PACKAGE__->meta->make_immutable;
```

Wire up: `__PACKAGE__->resultset_class('MyApp::Schema::ResultSet::Artist');`

## Test schemas

| Schema | Style |
|---|---|
| `DBIO::Test::Schema::Moose` | Moose + Vanilla |
| `DBIO::Test::Schema::MooseSugar` | Moose + Cake |

Each: Artist + CD, has_many/belongs_to, custom (Artist) + default (CD) ResultSet, all `make_immutable`. Core tests use `DBIO::Test::Storage`; driver tests do real DB round-trip.
