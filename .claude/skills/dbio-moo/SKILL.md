---
name: dbio-moo
description: "DBIO::Moo bridge — Moo attributes in DBIO Result classes, Schema classes, and ResultSet classes. Combinations with Cake and Candy."
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

Bridge: Moo attrs + DBIO columns coexist. Optional (`suggests` in cpanfile).

## What `use DBIO::Moo` does

1. `use Moo` in caller
2. `extends 'DBIO::Core'`
3. Installs `FOREIGNBUILDARGS` — filters constructor args, only DBIO-known keys (columns, rels, `-` internals) forwarded to `DBIO::Row::new`

Without filter: `DBIO::Row::new` calls `store_column` per key, dies on unknown columns (Moo attrs).

## Two construction paths

| Path | Trigger | Moo `new()` runs? |
|---|---|---|
| `new()` | `create()`, `new_result()` | yes — FOREIGNBUILDARGS filters, then `DBIO::Row::new` |
| `inflate_result()` | `find`/`search`/`all` (any DB fetch) | NO — blesses hash, bypasses `new()` |

## Lazy is mandatory

Moo attrs with defaults **must** be `lazy => 1`. Non-lazy defaults set in `new()`, missed by `inflate_result`.

```perl
# WRONG — undef on DB-fetched rows
has score => (is=>'rw', default=>sub{0});
# CORRECT
has score => (is=>'rw', lazy=>1, default=>sub{0});
has display_name => (is=>'lazy');   # 'lazy' is inherently lazy
sub _build_display_name { 'Artist: '.$_[0]->name }
```

## Result class — Vanilla columns

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Moo;
__PACKAGE__->table('artist');
__PACKAGE__->add_columns(
  id   => { data_type=>'integer', is_auto_increment=>1 },
  name => { data_type=>'varchar', size=>100 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(cds => 'MyApp::Schema::Result::CD', 'artist_id');
has display_name => (is=>'lazy');
sub _build_display_name { 'Artist: '.$_[0]->name }
1;
```

## With Cake — Moo FIRST, then Cake

```perl
use DBIO::Moo;
use DBIO::Cake;
table 'artist';
col id   => integer auto_inc;
col name => varchar(100);
primary_key 'id';
has_many cds => 'MyApp::Schema::Result::CD', 'artist_id';
has display_name => (is=>'lazy');
```

## With Candy

```perl
use DBIO::Moo;
use DBIO::Candy;
table 'artist';
column id   => { data_type=>'integer', is_auto_increment=>1 };
column name => { data_type=>'varchar', size=>100 };
primary_key 'id';
has display_name => (is=>'lazy');
```

## Schema class

```perl
package MyApp::Schema;
use Moo;
extends 'DBIO::Schema';
has verbose => (is=>'rw', lazy=>1, default=>sub{0});
__PACKAGE__->load_namespaces;
1;
```

## Custom ResultSet

`DBIO::ResultSet::new` takes positional args, doesn't reject unknown keys → trivial pass-through:

```perl
package MyApp::Schema::ResultSet::Artist;
use Moo;
extends 'DBIO::ResultSet';
sub FOREIGNBUILDARGS { my ($class, @args) = @_; return @args }
has default_limit => (is=>'rw', lazy=>1, default=>sub{100});
sub active  { $_[0]->search({active=>1}) }
sub by_name { $_[0]->search({name=>$_[1]}) }
1;
```

Wire up: `__PACKAGE__->resultset_class('MyApp::Schema::ResultSet::Artist');`

## Gotcha

FOREIGNBUILDARGS silently drops keys that aren't column/rel/`-prefix`. Cannot tell Moo attr from typo — both vanish before `DBIO::Row::new`.

## Test schemas

| Schema | Style |
|---|---|
| `DBIO::Test::Schema::Moo` | Moo + Vanilla |
| `DBIO::Test::Schema::MooCake` | Moo + Cake |

Each: Artist + CD, has_many/belongs_to, custom ResultSet (Artist), default (CD). Core tests use `DBIO::Test::Storage` (fake); driver tests do real DB round-trip.
