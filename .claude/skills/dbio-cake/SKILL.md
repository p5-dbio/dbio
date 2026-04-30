---
name: dbio-cake
description: "DBIO::Cake DDL-like DSL for Result classes — the most concise style. Use when project uses 'use DBIO::Cake'"
user-invocable: false
allowed-tools: Read, Grep, Glob
model: sonnet
---

DDL-like DSL for DBIO Result classes. Most concise of the three styles. Trigger: `use DBIO::Cake` in a Result class.

## What `use DBIO::Cake` does

1. `strict` + `warnings`
2. Inherits from `DBIO::Core`
3. Exports DSL keywords
4. `namespace::clean` autoclean

## Example

```perl
package MyApp::Schema::Result::Artist;
use DBIO::Cake;

table 'artist';
col id           => integer, unsigned, auto_inc;
col name         => varchar(25), null;
col formed       => date;
col last_update  => datetime('UTC');
primary_key 'id';
unique artist_name => ['name'];
idx    artist_by_name => ['name'];
has_many albums => 'MyApp::Schema::Result::Album', 'artist_id';
1;
```

## Import flags

```perl
use DBIO::Cake;                     # defaults
use DBIO::Cake -inflate_datetime;   # inflate date/datetime
use DBIO::Cake -inflate_json;       # inflate json/jsonb
use DBIO::Cake -inflate_jsonb;      # inflate jsonb only
use DBIO::Cake -retrieve_defaults;  # retrieve_on_insert for defaults
use DBIO::Cake -no_autoclean;       # keep DSL symbols
use DBIO::Cake '-Pg';               # = -inflate_jsonb,-inflate_datetime,-retrieve_defaults
use DBIO::Cake '-MySQL';            # driver shortcut (cake_defaults)
use DBIO::Cake '-SQLite';           # driver shortcut (cake_defaults)
```

Driver shortcut: looks up storage via `DBIO::Storage::DBI` registry, calls `cake_defaults()`. Explicit flags after override.

## Column types

- Integers: `integer`, `tinyint`, `smallint`, `bigint`
- Auto-inc: `serial`, `bigserial`, `smallserial` (imply `is_auto_increment`)
- Numeric: `numeric($p,$s)`, `decimal($p,$s)`, `money`
- Float: `real`/`float4`, `double`/`float8`, `float($bits)`
- String: `char($n)`, `varchar($n)`
- Text: `text`, `tinytext`, `mediumtext`, `longtext`
- Binary: `blob`, `tinyblob`, `mediumblob`, `longblob`, `bytea`
- Bool: `boolean`/`bool`
- Date/time: `date`, `datetime($tz)`, `timestamp($tz)`, `time($tz)`, `timestamptz`, `timetz`, `interval`
- `enum('a','b')`, `uuid`, `json`, `jsonb`, `xml`, `hstore`
- PG arrays: `array('text')` or `array({data_type=>...})`
- pgvector: `vector($d)`, `halfvec($d)`, `sparsevec($d)`
- Bit: `bit($n)`, `varbit($n)`
- PG net: `inet`, `cidr`, `macaddr`, `macaddr8`
- PG fts: `tsvector`, `tsquery`
- PG geom: `point`, `line`, `lseg`, `box`, `path`, `polygon`, `circle`
- PG ranges: `int4range`, `int8range`, `numrange`, `tsrange`, `tstzrange`, `daterange`

## Modifiers (comma-chain after type)

- `null` → `is_nullable=>1` (default = NOT NULL)
- `auto_inc` → `is_auto_increment=>1`
- `fk` → `is_foreign_key=>1`
- `unsigned` → `extra=>{unsigned=>1}` (MySQL)
- `default($v)` → `default_value=>$v`

## Relationships

```perl
belongs_to   artist  => 'MyApp::Schema::Result::Artist',  'artist_id';
has_one      profile => 'MyApp::Schema::Result::Profile', 'user_id';
has_many     tracks  => 'MyApp::Schema::Result::Track',   'album_id';
might_have   bio     => 'MyApp::Schema::Result::Bio',     'artist_id';
many_to_many tags    => 'album_tags', 'tag';
rel_one      publisher => 'MyApp::Schema::Result::Publisher', 'publisher_id'; # left-join
rel_many     reviews   => 'MyApp::Schema::Result::Review',    'album_id';     # left-join
```

Cascades:
```perl
belongs_to artist => 'MyApp::Schema::Result::Artist', 'artist_id', { ddl_cascade };  # ON DELETE/UPDATE CASCADE
has_many tracks   => 'MyApp::Schema::Result::Track',  'album_id',  { dbic_cascade }; # cascade_delete + cascade_copy
```

## Constraints / indexes

```perl
primary_key 'id';
primary_key 'a_id', 'b_id';
unique ['email'];
unique email_uniq => ['email'];
idx name_idx => ['name'];
idx composite => ['last','first'], type => 'unique';
```

## Views

```perl
view 'active_artists', 'SELECT * FROM artist WHERE active=1';
col id => integer; col name => varchar(100);
```

## With Moo / Moose

Load OO bridge **first**, then Cake:
```perl
use DBIO::Moo;          # or DBIO::Moose
use DBIO::Cake;
table 'artist';
col id   => integer, auto_inc;
col name => varchar(100);
primary_key 'id';
has display_name => ( is => 'lazy' );    # ALL Moo/Moose attrs with defaults MUST be lazy
sub _build_display_name { 'Artist: '.$_[0]->name }
```
Order matters — Cake calls `add_columns` at compile time, needs `DBIO::Core` already in @ISA. `lazy=>1` is mandatory because `inflate_result` bypasses `new()` (see `dbio-core`). Moose: `__PACKAGE__->meta->make_immutable;`.

## Rules

1. Columns NOT NULL by default — use `null`
2. Types return flat key-value lists — chain freely
3. `1;` optional with `-V2`, harmless otherwise
4. Symbols auto-cleaned (no namespace pollution)
5. Always full class names in relationships, never monikers
6. Nullable = `null` keyword (not `is_nullable` — that's Vanilla)
